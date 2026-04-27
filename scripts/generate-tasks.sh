#!/bin/bash
# Generate workspace.code-workspace from config/repos.conf (SOT)
# Includes folders + terminal tasks with runOn: folderOpen
# "group": "repos" = side-by-side split terminals

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/load-workspace-repos.sh"
source "${SCRIPT_DIR}/colors.sh"

WORKSPACE_FILE="${POLYFORGE_ROOT}/workspace.code-workspace"

# Build folders array — polyforge + relative paths from gh_repo entries
folders='[{"path": ".", "name": "polyforge"}]'
for i in "${!GH_REPOS[@]}"; do
  folders=$(echo "$folders" | jq \
    --arg p "../${GH_REPOS[$i]}" \
    --arg n "${REPO_NAMES[$((i+1))]}" \
    '. + [{"path": $p, "name": $n}]')
done

# Build tasks array with resolved absolute paths
tasks="[]"
for i in "${!REPOS[@]}"; do
  tasks=$(echo "$tasks" | jq \
    --arg label "${REPO_NAMES[$i]}" \
    --arg cwd "${REPOS[$i]}" \
    '. + [{
      "label": $label,
      "type": "shell",
      "command": "exec $SHELL",
      "options": { "cwd": $cwd },
      "runOptions": { "runOn": "folderOpen" },
      "presentation": { "group": "repos", "reveal": "always" },
      "problemMatcher": []
    }]')
done

# Write workspace file (folders + settings + tasks)
# task.allowAutomaticTasks: "on" lets folderOpen tasks run without the per-workspace prompt
jq -n \
  --argjson folders "$folders" \
  --argjson tasks "$tasks" \
  '{
    folders: $folders,
    settings: {"task.allowAutomaticTasks": "on"},
    tasks: {version: "2.0.0", tasks: $tasks}
  }' \
  > "$WORKSPACE_FILE"

success "Generated $WORKSPACE_FILE with ${#REPOS[@]} repos and tasks"
