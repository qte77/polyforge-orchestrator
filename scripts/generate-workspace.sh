#!/bin/bash
# Generate workspace.code-workspace from repos.conf (folders only)
# VS Code auto-detects this file for multi-root sidebar
# Terminals handled by tmux via cc-repos.sh in postAttachCommand

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/repos.conf"

WORKSPACE_FILE="${SCRIPT_DIR}/../workspace.code-workspace"

folders=""
for i in "${!REPOS[@]}"; do
  [[ -n "$folders" ]] && folders+=","
  folders+=$'\n'"    { \"path\": \"${REPOS[$i]}\", \"name\": \"${REPO_NAMES[$i]}\" }"
done

cat > "$WORKSPACE_FILE" <<EOF
{
  "folders": [${folders}
  ]
}
EOF
echo "Generated $WORKSPACE_FILE with ${#REPOS[@]} folders"
