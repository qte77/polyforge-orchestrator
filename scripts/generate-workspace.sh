#!/bin/bash
# Generate workspace.code-workspace from repos.conf
# Ensures paths match the actual runtime environment

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/repos.conf"

WORKSPACE_FILE="${SCRIPT_DIR}/../workspace.code-workspace"

folders=""
tasks=""
for i in "${!REPOS[@]}"; do
  path="${REPOS[$i]}"
  name="${REPO_NAMES[$i]}"

  [[ -n "$folders" ]] && folders+=","
  folders+=$'\n'"    { \"path\": \"${path}\", \"name\": \"${name}\" }"

  # Shell task per repo — same group = side-by-side split terminals
  [[ -n "$tasks" ]] && tasks+=","
  tasks+=$'\n'"      {"
  tasks+=$'\n'"        \"label\": \"${name}\","
  tasks+=$'\n'"        \"type\": \"shell\","
  tasks+=$'\n'"        \"command\": \"exec \$SHELL\","
  tasks+=$'\n'"        \"options\": { \"cwd\": \"${path}\" },"
  tasks+=$'\n'"        \"runOptions\": { \"runOn\": \"folderOpen\" },"
  tasks+=$'\n'"        \"presentation\": { \"group\": \"repos\", \"reveal\": \"always\" },"
  tasks+=$'\n'"        \"problemMatcher\": []"
  tasks+=$'\n'"      }"
done

cat > "$WORKSPACE_FILE" <<EOF
{
  "folders": [${folders}
  ],
  "settings": {
    "task.allowAutomaticTasks": "on"
  },
  "tasks": {
    "version": "2.0.0",
    "tasks": [${tasks}
    ]
  }
}
EOF
echo "Generated $WORKSPACE_FILE with ${#REPOS[@]} folders and terminal tasks"
