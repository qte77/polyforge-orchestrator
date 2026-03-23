#!/bin/bash
# Generate workspace.code-workspace from repos.conf
# Includes folders, auto-open terminal tasks, and settings
# Pattern: https://jackharner.com/blog/auto-open-terminals-vs-code-workspace/

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/repos.conf"

WORKSPACE_FILE="${SCRIPT_DIR}/../workspace.code-workspace"

folders=""
tasks=""
depends=""
for i in "${!REPOS[@]}"; do
  path="${REPOS[$i]}"
  name="${REPO_NAMES[$i]}"

  [[ -n "$folders" ]] && folders+=","
  folders+=$'\n'"    { \"path\": \"${path}\", \"name\": \"${name}\" }"

  [[ -n "$tasks" ]] && tasks+=","
  tasks+=$'\n'"      {"
  tasks+=$'\n'"        \"label\": \"${name}\","
  tasks+=$'\n'"        \"type\": \"shell\","
  tasks+=$'\n'"        \"command\": \"/bin/bash\","
  tasks+=$'\n'"        \"isBackground\": true,"
  tasks+=$'\n'"        \"options\": { \"cwd\": \"${path}\" },"
  tasks+=$'\n'"        \"runOptions\": { \"runOn\": \"folderOpen\" },"
  tasks+=$'\n'"        \"presentation\": { \"group\": \"repos\", \"reveal\": \"always\" },"
  tasks+=$'\n'"        \"problemMatcher\": []"
  tasks+=$'\n'"      }"

  [[ -n "$depends" ]] && depends+=", "
  depends+="\"${name}\""
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
    "tasks": [
      {
        "label": "Open All Terminals",
        "dependsOn": [${depends}],
        "runOptions": { "runOn": "folderOpen" },
        "problemMatcher": []
      },${tasks}
    ]
  }
}
EOF
echo "Generated $WORKSPACE_FILE with ${#REPOS[@]} folders and terminal tasks"
