#!/usr/bin/env bash
# estate-status.sh — Read-only GitHub estate sweep: open PRs, issues, Dependabot + CodeQL alerts,
# CodeFactor and CI state on the default branch, open TODO.md items, and notifications, across
# every source repo an owner has on GitHub. Writes nothing to GitHub.
#
# Scope: --scope public (default) scans public repos only; --scope private scans private repos
# only; --scope all scans both. Private repos are never printed by name -- only as masked labels
# (private-NN) in stdout, files, and error messages; their PR/issue titles are masked too. The
# private-NN numbering is assigned from the full repo set before the --scope filter is applied, so
# a given repo keeps the same label across scopes. CodeFactor grades come from the public badge on
# www.codefactor.io and are fetched for public repos only.
#
# Repos with an open Claude Code session (interactive, or background not in
# blocked/done/failed/stopped) are skipped; recent non-bot PRs elsewhere are listed as "in
# flight". That skip check is best-effort: if the `claude` CLI is unavailable it warns and skips
# nothing, it never blocks the sweep.
#
# Fails loudly (non-zero exit, message on stderr, no summary written) when the initial repo
# listing or the notifications call errors, or when the scan covers 0 repos -- instead of silently
# reporting an all-zero summary as if the estate were clear (see CHANGELOG for the incident this
# fixes). Per-repo alert/PR/issue calls keep the original soft-degradation: a failed call for one
# repo shows as "n/a" / "ERR" in its row rather than aborting the whole sweep.
#
# Usage: estate-status.sh [--owner NAME] [--scope public|private|all] [--out DIR]
# Output: <out>/estate-status-<date>/{repos,prs,issues,alerts,notifications,excluded}.tsv + summary.md
set -uo pipefail  # not -e: several counts below use `grep -c`, which exits 1 by design on no match

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/colors.sh"

OWNER="qte77"
SCOPE="public"
OUT_BASE="${REPO_ROOT}/runs/estate-status"

usage() {
  head -25 "$0" | grep '^#' | sed 's/^# \?//'
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --owner) OWNER="$2"; shift 2 ;;
    --scope) SCOPE="$2"; shift 2 ;;
    --out) OUT_BASE="$2"; shift 2 ;;
    --help|-h) usage ;;
    *) error "Unknown option: $1"; usage ;;
  esac
done

[[ "$SCOPE" =~ ^(public|private|all)$ ]] || { error "--scope must be public, private, or all (got: $SCOPE)"; exit 1; }
[[ "$OWNER" =~ ^[A-Za-z0-9-]+$ ]] || { error "--owner looks malformed (got: $OWNER)"; exit 1; }

out="${OUT_BASE}-$(date -u +%F)"
mkdir -p "$out"
G() { env -u GH_TOKEN -u GITHUB_TOKEN gh "$@"; }

# A second concurrent run for the same owner+date would share the scratch files below
# (.repos.raw, .pr, .iss) with no locking, and could race: one run's truncate-and-rewrite of
# .repos.raw can interleave with another run already reading it, so a slow or failing `gh` call
# in one run can leave the other reading an empty file -- a silent false "0 repos scanned". Claim
# one lock per output directory so a collision fails loudly instead of racing. (If a prior run was
# killed without cleanup, remove the stale "$out/.lock" directory by hand.)
lockdir="$out/.lock"
if ! mkdir "$lockdir" 2>/dev/null; then
  error "another estate-status run already owns $out ($lockdir exists) -- wait for it to finish, or pass --out for a separate directory"
  exit 1
fi
trap 'rmdir "$lockdir" 2>/dev/null' EXIT

# --- repo set --------------------------------------------------------------------------------
# List the full repo set once, so private-NN numbering stays stable across --scope values, then
# filter down to the requested scope for the actual scan.
if ! G repo list "$OWNER" --no-archived --source --limit 400 \
  --json name,isPrivate,defaultBranchRef \
  --jq '.[] | [.name, (.isPrivate|tostring), (.defaultBranchRef.name // "main")] | @tsv' \
  | sort -f > "$out/.repos.raw"; then
  error "gh repo list for '$OWNER' failed -- check 'gh auth status' and network, then retry"
  exit 1
fi

declare -A label
n=0
total=0
while IFS=$'\t' read -r name priv _; do
  total=$((total+1))
  if [[ $priv == true ]]; then n=$((n+1)); label[$name]=$(printf 'private-%02d' "$n"); else label[$name]=$name; fi
done < "$out/.repos.raw"

if [[ $total -eq 0 ]]; then
  error "0 repos returned for owner '$OWNER' -- check the owner name and 'gh auth status'; refusing to write a summary"
  exit 1
fi

: > "$out/.repos.scoped"
while IFS=$'\t' read -r name priv branch; do
  case "$SCOPE" in
    public)  [[ $priv == false ]] || continue ;;
    private) [[ $priv == true ]]  || continue ;;
    all) ;;
  esac
  printf '%s\t%s\t%s\n' "$name" "$priv" "$branch" >> "$out/.repos.scoped"
done < "$out/.repos.raw"

if [[ ! -s "$out/.repos.scoped" ]]; then
  error "0 of $total repos match --scope $SCOPE for owner '$OWNER' -- refusing to write a summary"
  exit 1
fi

# --- exclusions: repos with an open Claude Code session ---------------------------------------
declare -A skip
: > "$out/excluded.tsv"
if command -v claude > /dev/null 2>&1; then
  while IFS=$'\t' read -r kind state cwd; do
    url=$(git -C "$cwd" remote get-url origin 2>/dev/null) || continue
    repo=$(sed -E 's#(\.git)?/?$##; s#.*[:/]([^/]+)/([^/]+)$#\1/\2#' <<<"$url")
    [[ ${repo%%/*} == "$OWNER" ]] || continue
    r=${repo#*/}; [[ -n ${label[$r]:-} ]] || continue
    skip[$r]=1
    printf '%s\t%s\t%s\n' "${label[$r]}" "$kind" "${state:-open}" >> "$out/excluded.tsv"
  done < <(claude agents --json 2>/dev/null | jq -r '.[]
    | select(.kind=="interactive" or ((.state // "") | IN("blocked","done","failed","stopped") | not))
    | [.kind, (.state // "-"), .cwd] | @tsv')
else
  warn "claude CLI not found -- skipping the open-session check (nothing excluded)"
fi

# --- per repo --------------------------------------------------------------------------------
printf 'repo\tprs\tprs_bot\tprs_failing\tissues\tdep_crit\tdep_high\tdep_other\tcq_crit_high\tcq_other\tprs_codefactor_not_green\tmain_failing\ttodo_open\tcodefactor_required\tcodefactor_grade\n' > "$out/repos.tsv"
printf 'repo\tpr\tauthor\tdraft\tmerge_state\tfailing\tpending\tcodefactor\tupdated\ttitle\n' > "$out/prs.tsv"
printf 'repo\tissue\tauthor\tlabels\tupdated\ttitle\n' > "$out/issues.tsv"
printf 'repo\tsource\tseverity\tpackage_or_rule\tcreated\n' > "$out/alerts.tsv"

while IFS=$'\t' read -r name priv branch; do
  [[ -n ${skip[$name]:-} ]] && continue
  L=${label[$name]}; R="$OWNER/$name"
  # Private repos: titles can carry names, so only counts and states are kept.
  t='.title'; [[ $priv == true ]] && t='"-"'

  G pr list -R "$R" --state open --limit 100 \
    --json number,title,author,isDraft,mergeStateStatus,statusCheckRollup,updatedAt --jq ".[]
    | ([.statusCheckRollup[]? | {n:(.name // .context), s:(if .__typename==\"CheckRun\" and .status!=\"COMPLETED\" then \"PENDING\" else (.conclusion // .state) end)}]) as \$c
    | [\"$L\", (.number|tostring), .author.login, (.isDraft|tostring), .mergeStateStatus,
       ([\$c[]|select(.s|IN(\"FAILURE\",\"ERROR\",\"CANCELLED\",\"TIMED_OUT\",\"ACTION_REQUIRED\",\"STARTUP_FAILURE\"))|.n]|join(\",\")),
       ([\$c[]|select(.s|IN(\"PENDING\",\"QUEUED\",\"IN_PROGRESS\",\"EXPECTED\"))|.n]|join(\",\")),
       (([\$c[]|select(.n|test(\"codefactor\";\"i\"))|.s]|first) // \"absent\"),
       .updatedAt[0:10], $t] | @tsv" > "$out/.pr" 2>/dev/null
  cat "$out/.pr" >> "$out/prs.tsv"

  G issue list -R "$R" --state open --limit 300 --json number,title,author,labels,updatedAt --jq ".[]
    | [\"$L\", (.number|tostring), .author.login, ([.labels[].name]|join(\",\")), .updatedAt[0:10], $t] | @tsv" \
    > "$out/.iss" 2>/dev/null
  cat "$out/.iss" >> "$out/issues.tsv"

  dep=$(G api "repos/$R/dependabot/alerts?state=open&per_page=100" --paginate \
    --jq ".[] | [\"$L\",\"dependabot\",.security_advisory.severity,.dependency.package.name,.created_at[0:10]] | @tsv" 2>/dev/null) \
    || dep="ERR"
  cq=$(G api "repos/$R/code-scanning/alerts?state=open&per_page=100" --paginate \
    --jq ".[] | [\"$L\",\"codeql\",(.rule.security_severity_level // .rule.severity),.rule.id,.created_at[0:10]] | @tsv" 2>/dev/null) \
    || cq="ERR"
  [[ -n $dep && $dep != ERR ]] && printf '%s\n' "$dep" >> "$out/alerts.tsv"
  [[ -n $cq && $cq != ERR ]] && printf '%s\n' "$cq" >> "$out/alerts.tsv"

  # CodeFactor posts only on PRs, not on the default branch: count open PRs where it is not green.
  cf=$(cut -f8 "$out/.pr" | grep -vc '^SUCCESS$')
  mf=$(G api "repos/$R/commits/$branch/check-runs?per_page=100" \
    --jq '[.check_runs[]|select(.conclusion|IN("failure","timed_out","cancelled","startup_failure","action_required"))|.name]|unique|join(",")' \
    2>/dev/null) || mf="ERR"
  todo=$(G api "repos/$R/contents/TODO.md" --jq .content 2>/dev/null | base64 -d 2>/dev/null \
    | grep -cE '^[[:space:]]*[-*] \[ \]') || todo=${todo:-0}
  # Is CodeFactor a required status check in the default branch's rulesets? (legacy branch
  # protection is not read, so "no" means "not in a ruleset")
  cfr=$(G api "repos/$R/rules/branches/$branch" --jq '[.[]|select(.type=="required_status_checks")
    |.parameters.required_status_checks[].context|select(test("codefactor";"i"))]|if length>0 then "yes" else "no" end' \
    2>/dev/null) || cfr="n/a"
  # CodeFactor grade from its public badge (public repos only; private names never leave the machine)
  cfg="n/a"; [[ $priv == false ]] && cfg=$(printf '%s\n' "$name" | python3 -I "$SCRIPT_DIR/codefactor-grade.py" "$OWNER" | cut -f2)

  cnt() { [[ $1 == ERR ]] && { echo "n/a"; return; }; [[ -z $1 ]] && { echo 0; return; }; grep -cE "$2" <<<"$1"; }
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$L" \
    "$(wc -l < "$out/.pr")" \
    "$(cut -f3 "$out/.pr" | grep -ciE 'dependabot|renovate|github-actions')" \
    "$(cut -f6 "$out/.pr" | grep -c .)" \
    "$(wc -l < "$out/.iss")" \
    "$(cnt "$dep" $'\tcritical\t')" "$(cnt "$dep" $'\thigh\t')" "$(cnt "$dep" $'\t(medium|low)\t')" \
    "$(cnt "$cq" $'\t(critical|high|error)\t')" "$(cnt "$cq" $'\t(medium|low|warning|note)\t')" \
    "$cf" "${mf:-}" "$todo" "$cfr" "$cfg" >> "$out/repos.tsv"
done < "$out/.repos.scoped"

# --- notifications (unread; never marked read) ------------------------------------------------
if ! notif_raw=$(G api notifications --paginate --jq '.[] | [.repository.name, (.repository.private|tostring), .reason, .subject.type, .updated_at[0:10], .subject.title] | @tsv'); then
  error "gh api notifications failed -- check 'gh auth status' and network, then retry"
  exit 1
fi
{
  printf 'repo\treason\ttype\tupdated\ttitle\n'
  printf '%s\n' "$notif_raw" | while IFS=$'\t' read -r name priv reason type upd title; do
    [[ -z ${name:-} ]] && continue
    if [[ $priv == true ]]; then printf '%s\t%s\t%s\t%s\t-\n' "${label[$name]:-private-other}" "$reason" "$type" "$upd"
    else printf '%s\t%s\t%s\t%s\t%s\n' "$name" "$reason" "$type" "$upd" "$title"; fi
  done
} > "$out/notifications.tsv"

rm -f "$out/.pr" "$out/.iss" "$out/.repos.raw" "$out/.repos.scoped"

# --- summary ---------------------------------------------------------------------------------
{
  echo "# Estate status $(date -u +%FT%TZ) (owner: $OWNER, scope: $SCOPE)"
  echo
  printf -- '- repos scanned: %s (excluded for open sessions: %s)\n' "$(($(wc -l < "$out/repos.tsv")-1))" "$(wc -l < "$out/excluded.tsv")"
  printf -- '- open PRs: %s, issues: %s, notifications: %s\n' "$(($(wc -l < "$out/prs.tsv")-1))" "$(($(wc -l < "$out/issues.tsv")-1))" "$(($(wc -l < "$out/notifications.tsv")-1))"
  printf -- '- CodeFactor required check in default-branch rulesets: %s yes, %s no, %s n/a\n' "$(cut -f14 "$out/repos.tsv" | grep -cx yes)" "$(cut -f14 "$out/repos.tsv" | grep -cx no)" "$(cut -f14 "$out/repos.tsv" | grep -cx n/a)"
  awk -F'\t' 'NR>1{for(i=6;i<=10;i++) if($i!="n/a") s[i]+=$i} END{printf "- Dependabot critical/high/other: %d/%d/%d; CodeQL critical-high/other: %d/%d\n",s[6],s[7],s[8],s[9],s[10]}' "$out/repos.tsv"
  echo
  echo "## Repos needing attention (any PR, failing check, alert, PR without green CodeFactor, open TODO, CodeFactor not required, or grade below A)"
  echo
  echo '| repo | PRs (bot/failing) | issues | dep c/h/o | CodeQL ch/o | PRs CodeFactor not green | main failing | TODO | CodeFactor required | CodeFactor grade |'
  echo '|---|---|---|---|---|---|---|---|---|---|'
  awk -F'\t' 'NR>1 && ($2>0 || $6+$7+$8+$9+$10>0 || $11>0 || $12!="" || $13>0 || $14=="no" || ($15!="n/a" && $15!~/^A/)) {
    printf "| %s | %s (%s/%s) | %s | %s/%s/%s | %s/%s | %s | %s | %s | %s | %s |\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15}' "$out/repos.tsv"
  # Sessions can open PRs in repos they are not "in", so recent non-bot PRs count as in flight.
  since=$(date -u -d '1 day ago' +%F)
  echo
  echo "## In flight (non-bot PRs updated since $since: check who owns them before touching)"
  echo
  awk -F'\t' -v c="$since" 'NR>1 && $3 !~ /^app\// && $9 >= c {printf "- %s#%s (%s, %s) %s\n",$1,$2,$3,$9,$10}' "$out/prs.tsv"
} > "$out/summary.md"
echo "$out"
