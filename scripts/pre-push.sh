#!/usr/bin/env bash

set -euo pipefail

# This script is used by pre-commit (pre-push hook).
# It validates commit messages when pushing to the main branch.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common-rules.sh"

ORIGINAL_BRANCH=$CURRENT_BRANCH

while read -r local_ref local_sha remote_ref remote_sha; do
  # Only validate when pushing to main
  if [[ "$remote_ref" != "refs/heads/main" ]]; then
    continue
  fi

  echo "Validating commits for push to 'main'..."

  if [[ "$remote_sha" =~ ^0+$ ]]; then
    range="$local_sha"
  else
    range="$remote_sha..$local_sha"
  fi

  commits=$(git rev-list "$range")
  if [ -z "$commits" ]; then
    echo "No new commits to validate."
    continue
  fi

  echo "Commits to validate:"
  git log --oneline "$range"

  # Use main-branch rules for validation
  CURRENT_BRANCH="main"

  for commit_hash in $commits; do
    message=$(git log --format=%B -n 1 "$commit_hash" | head -n1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    if ! validate_commit_message "$message"; then
      echo -e "${RED}Push rejected. Commit $commit_hash does not conform to the 'main' branch commit message format.${NC}"
      CURRENT_BRANCH=$ORIGINAL_BRANCH
      exit 1
    fi
  done

  CURRENT_BRANCH=$ORIGINAL_BRANCH
  echo -e "${GREEN}All commit messages for push to 'main' are valid.${NC}"
done

exit 0
