#!/bin/bash
# Generate workspace.code-workspace from repos.conf
# Ensures paths match the actual runtime environment

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
