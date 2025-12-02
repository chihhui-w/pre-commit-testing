#!/usr/bin/env bash

set -euo pipefail

# This script is used by pre-commit (pre-push hook).
# It validates commit messages when pushing to the main branch.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common-rules.sh"

ORIGINAL_BRANCH=$CURRENT_BRANCH

handled_main_ref=false

# 這裡依照 git pre-push hook 的標準介面：
# stdin 每一行是：<local ref> <local sha1> <remote ref> <remote sha1>
while read -r local_ref local_sha remote_ref remote_sha; do
  # 只在「要推到 main」的那一條 ref 上做檢查
  if [[ "$remote_ref" != "refs/heads/main" ]]; then
    continue
  fi

  handled_main_ref=true

  echo "Validating commits for push to 'main'..."

  # remote_sha 是遠端目前 main 的 commit
  # local_sha 是你要推上去的本地 head
  if [[ "$remote_sha" =~ ^0+$ ]]; then
    # 遠端還沒有 main（第一次 push）：檢查 local_sha 這顆 commit（和它之前的全部）
    range="$local_sha"
  else
    # 一般情況：只檢查「遠端 main 沒有」的那段
    range="$remote_sha..$local_sha"
  fi

  commits=$(git rev-list "$range" 2>/dev/null || true)
  if [ -z "$commits" ]; then
    echo "No new commits to validate."
    continue
  fi

  echo "Commits to validate:"
  git log --oneline "$range"

  # 強制套用 main branch 的規則
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

# 如果這次 push 根本沒有涉及 remote main（例如只 push tag 或其他 branch），就直接結束
if [ "$handled_main_ref" = false ]; then
  exit 0
fi

exit 0
