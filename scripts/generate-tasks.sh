#!/bin/bash
# Generate .vscode/tasks.json from workspace.code-workspace
# Each workspace folder gets a terminal task with runOn: folderOpen
# "group": "repos" = side-by-side split terminals
# Remove "group" for tabbed terminals instead

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/workspace-repos.sh"

TASKS_FILE="${POLYFORGE_ROOT}/.vscode/tasks.json"
mkdir -p "$(dirname "$TASKS_FILE")"

tasks=""
for i in "${!REPOS[@]}"; do
  [[ -n "$tasks" ]] && tasks+=","
  tasks+=$(cat <<EOF

      {
        "label": "${REPO_NAMES[$i]}",
        "type": "shell",
        "command": "exec \$SHELL",
        "options": { "cwd": "${REPOS[$i]}" },
        "runOptions": { "runOn": "folderOpen" },
        "presentation": { "group": "repos", "reveal": "always" },
        "problemMatcher": []
      }
EOF
  )
done

cat > "$TASKS_FILE" <<EOF
{
  "version": "2.0.0",
  "tasks": [${tasks}
  ]
}
EOF

echo "Generated $TASKS_FILE with ${#REPOS[@]} tasks"
