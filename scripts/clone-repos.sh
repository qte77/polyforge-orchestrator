#!/bin/bash
# Clone all managed repos from config/repos.conf
# Uses GH_REPOS (owner/repo) for clone URL, REPOS for local path

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/load-workspace-repos.sh"
source "${SCRIPT_DIR}/colors.sh"

for i in "${!GH_REPOS[@]}"; do
  gh_repo="${GH_REPOS[$i]}"
  path="${REPOS[$((i+1))]}"
  name="${REPO_NAMES[$((i+1))]}"

  if [[ -d "$path" ]]; then
    info "${name}: exists (skipping)"
    continue
  fi

  info "${name}: cloning ${gh_repo}..."
  mkdir -p "$(dirname "$path")"
  git clone "https://github.com/${gh_repo}.git" "$path" 2>/dev/null || \
    error "Failed to clone ${gh_repo}"
done

success "Done. $(ls -d "${REPOS[@]:1}" 2>/dev/null | wc -l)/${#GH_REPOS[@]} repos available."
