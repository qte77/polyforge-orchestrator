#!/bin/bash
# Generate workspace.code-workspace from repos.conf (folders only)
# Open manually for multi-root sidebar: Ctrl+Shift+P → Open Workspace from File
# Terminals are handled by postAttachCommand object format in devcontainer.json

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
