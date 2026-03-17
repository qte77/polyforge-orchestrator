#!/bin/bash
# cc-credential-setup.sh — Unify git credentials across all repos
# Usage: ./cc-credential-setup.sh
#
# Sets up git credential store and removes embedded PATs from remote URLs.
# Requires GH_PAT environment variable, ~/.gh_pat file, or .env.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../config/env-loader.sh"
source "${SCRIPT_DIR}/repos.conf"

if [[ -z "${GH_PAT:-}" ]]; then
  echo "Error: GH_PAT not set. Provide via .env, GH_PAT env var, or ~/.gh_pat."
  exit 1
fi

echo "Setting up unified git credential store..."

# Configure credential helper (skip if already set, e.g. Codespaces)
existing_helper=$(git config --global credential.helper 2>/dev/null || git config --system credential.helper 2>/dev/null || echo "")
if [[ -n "$existing_helper" ]]; then
  echo "  Credential helper already configured: $existing_helper (skipping)"
else
  git config --global credential.helper store
  GH_USER=$(git config --global user.name 2>/dev/null || echo "git")
  echo "https://${GH_USER}:${GH_PAT}@github.com" > ~/.git-credentials
  chmod 600 ~/.git-credentials
  echo "  Wrote ~/.git-credentials for ${GH_USER} (mode 600)"
fi

echo ""
echo "Cleaning embedded PATs from remote URLs..."

for repo in "${REPOS[@]}"; do
  if [[ ! -d "$repo/.git" ]]; then
    continue
  fi

  name=$(basename "$repo")
  current_url=$(git -C "$repo" remote get-url origin 2>/dev/null || echo "")

  if [[ "$current_url" == *"@github.com"* && "$current_url" == *":"*"@"* ]]; then
    # Extract clean URL: https://github.com/owner/repo.git
    clean_url=$(echo "$current_url" | sed -E 's|https://[^@]+@github.com|https://github.com|')
    git -C "$repo" remote set-url origin "$clean_url"
    echo "  $name: cleaned → $clean_url"
  else
    echo "  $name: already clean"
  fi
done

echo ""
echo "Verifying credential store works..."
for repo in "${REPOS[@]}"; do
  if [[ ! -d "$repo/.git" ]]; then
    continue
  fi
  name=$(basename "$repo")
  if git -C "$repo" ls-remote --exit-code origin HEAD &>/dev/null; then
    echo "  $name: OK"
  else
    echo "  $name: FAILED (check PAT permissions)"
  fi
done

echo ""
echo "Done. All repos now use ~/.git-credentials for auth."
