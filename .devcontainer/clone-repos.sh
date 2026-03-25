#!/bin/bash
# Clone all managed repos into the workspace
# Derives GitHub owner/repo from repos.conf paths — single source of truth

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../scripts/repos.conf"

# Default GitHub org (override via GITHUB_ORG env var)
ORG="${GITHUB_ORG:-qte77}"

for i in "${!REPOS[@]}"; do
  path="${REPOS[$i]}"
  name=$(basename "$path")

  if [[ -d "$path" ]]; then
    echo "  ${REPO_NAMES[$i]}: exists (skipping)"
    continue
  fi

  echo "  ${REPO_NAMES[$i]}: cloning..."
  mkdir -p "$(dirname "$path")"
  git clone "https://github.com/${ORG}/${name}.git" "$path" 2>/dev/null || \
    echo "  WARNING: Failed to clone ${ORG}/${name}"
done

echo "Done. $(ls -d "${REPOS[@]}" 2>/dev/null | wc -l)/${#REPOS[@]} repos available."

# Seed WakaTime config from Codespace secret (prevents interactive prompt)
if [[ -n "${WAKATIME_API_KEY:-}" && ! -f "$HOME/.wakatime.cfg" ]]; then
  cat > "$HOME/.wakatime.cfg" <<EOF
[settings]
api_key = ${WAKATIME_API_KEY}
api_url = https://api.wakatime.com/api/v1
heartbeat_rate_limit_seconds = 120
# disabled: silently blocks all tracking in repos without .wakatime-project
# include_only_with_project_file = true
# disabled: drops heartbeats for any project WakaTime can't resolve a name for
# exclude_unknown_project = true
offline = true
status_bar_enabled = true
status_bar_coding_activity = true
EOF
  echo "WakaTime: config seeded from WAKATIME_API_KEY"
fi

# Auto-attach to tmux repos session on terminal open
if ! grep -q 'tmux.*repos' "$HOME/.bashrc" 2>/dev/null; then
  cat >> "$HOME/.bashrc" <<'TMUX_BLOCK'

# Auto-attach to polyforge tmux session (added by clone-repos.sh)
if command -v tmux &>/dev/null && [ -z "${TMUX:-}" ] && tmux has-session -t repos 2>/dev/null; then
  exec tmux attach -t repos
fi
TMUX_BLOCK
  echo "tmux: auto-attach added to .bashrc"
fi
