#!/bin/bash
# Clone all managed repos into the workspace
# Derives GitHub owner/repo from repos.conf paths — single source of truth

set -euo pipefail

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
