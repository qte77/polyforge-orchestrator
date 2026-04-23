#!/bin/bash
# contrib-status.sh — Contribution dashboard across all fork repos
# Shows fork status, branches, open PRs, and worktrees

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/load-workspace-repos.sh"
source "${SCRIPT_DIR}/colors.sh"

# Header
printf "%-22s %-20s %-7s %-12s %s\n" "REPO" "BRANCH" "STATUS" "UPSTREAM" "OPEN PRS"
printf "%-22s %-20s %-7s %-12s %s\n" "----" "------" "------" "--------" "--------"

for i in "${!GH_REPOS[@]}"; do
  [[ "${FORK_FLAGS[$i]:-}" != "fork" ]] && continue

  gh_repo="${GH_REPOS[$i]}"
  path="${REPOS[$((i+1))]}"
  name="${REPO_NAMES[$((i+1))]}"

  if [[ ! -d "$path/.git" ]]; then
    printf "%-22s %s\n" "$name" "$(warn '(not cloned)')"
    continue
  fi

  # Branch
  branch=$(git -C "$path" branch --show-current 2>/dev/null || echo "detached")

  # Clean/dirty
  if git -C "$path" diff --quiet HEAD 2>/dev/null && \
     [[ -z "$(git -C "$path" status --porcelain 2>/dev/null)" ]]; then
    status="clean"
  else
    changed=$(git -C "$path" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    status="${changed}m"
  fi

  # Upstream sync status
  upstream_status="unknown"
  if git -C "$path" remote get-url upstream &>/dev/null; then
    local_head=$(git -C "$path" rev-parse HEAD 2>/dev/null)
    upstream_head=$(git -C "$path" rev-parse upstream/main 2>/dev/null || \
                    git -C "$path" rev-parse upstream/master 2>/dev/null || echo "")
    if [[ -n "$upstream_head" ]]; then
      if [[ "$local_head" == "$upstream_head" ]]; then
        upstream_status="synced"
      else
        behind=$(git -C "$path" rev-list --count HEAD..upstream/main 2>/dev/null || \
                 git -C "$path" rev-list --count HEAD..upstream/master 2>/dev/null || echo "?")
        upstream_status="${behind} behind"
      fi
    fi
  fi

  # Count open PRs by us on upstream
  pr_count=$(gh pr list -R "$gh_repo" --author "@me" --state open --json number 2>/dev/null | \
             jq 'length' 2>/dev/null || echo "?")

  printf "%-22s %-20s %-7s %-12s %s\n" "$name" "$branch" "$status" "$upstream_status" "$pr_count"

  # Show worktrees
  worktree_dir="${path}-worktrees"
  if [[ -d "$worktree_dir" ]]; then
    for wt in "$worktree_dir"/contrib-*; do
      [[ -d "$wt" ]] || continue
      wt_branch=$(git -C "$wt" branch --show-current 2>/dev/null || echo "?")
      printf "  %-20s %s\n" "$(basename "$wt")" "$wt_branch"
    done
  fi
done

echo ""
