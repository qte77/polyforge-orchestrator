#!/bin/bash
# Load REPOS, REPO_NAMES, and GH_REPOS arrays from config/repos.conf (SOT)
# Derives local paths as ../owner/repo relative to polyforge root
# Polyforge itself is always included as the first entry
# Usage: source scripts/load-workspace-repos.sh

POLYFORGE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPOS_CONF="${POLYFORGE_ROOT}/config/repos.conf"

if [[ ! -f "$REPOS_CONF" ]]; then
  echo "Error: $REPOS_CONF not found" >&2
  exit 1
fi

REPOS=("$POLYFORGE_ROOT")
REPO_NAMES=("polyforge")
GH_REPOS=()

while IFS=: read -r gh_repo name; do
  [[ -z "$gh_repo" || "$gh_repo" == \#* ]] && continue
  REPOS+=("$(realpath -m "$POLYFORGE_ROOT/../$gh_repo")")
  REPO_NAMES+=("$name")
  GH_REPOS+=("$gh_repo")
done < "$REPOS_CONF"
