#!/usr/bin/env bash

set -euo pipefail

# This script is used by pre-commit (pre-push hook).
# It validates commit messages when pushing to the main branch.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common-rules.sh"

ORIGINAL_BRANCH=$CURRENT_BRANCH

if [ "$CURRENT_BRANCH" != "main" ]; then
  exit 0
fi

UPSTREAM_REF=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "")

if [ "$UPSTREAM_REF" != "origin/main" ]; then
  exit 0
fi


if git rev-parse origin/main >/dev/null 2>&1; then
  RANGE="origin/main..HEAD"
else
  RANGE="HEAD"
fi

COMMITS=$(git rev-list "$RANGE")
if [ -z "$COMMITS" ]; then
  echo "No new commits to validate."
  exit 0
fi

echo "Validating commits for push to 'main'..."
echo "Commits to validate:"
git log --oneline "$RANGE"

CURRENT_BRANCH="main"

for commit_hash in $COMMITS; do
  message=$(git log --format=%B -n 1 "$commit_hash" | head -n1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  if ! validate_commit_message "$message"; then
    echo -e "${RED}Push rejected. Commit $commit_hash does not conform to the 'main' branch commit message format.${NC}"
    CURRENT_BRANCH=$ORIGINAL_BRANCH
    exit 1
  fi
done

CURRENT_BRANCH=$ORIGINAL_BRANCH
echo -e "${GREEN}All commit messages for push to 'main' are valid.${NC}"

exit 0
