#!/usr/bin/env bash

set -euo pipefail

# This script is used by pre-commit (pre-push hook).
# It validates commit messages when pushing to the main branch.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common-rules.sh"

ORIGINAL_BRANCH=$CURRENT_BRANCH

# 只在 main 分支時檢查
if [ "$CURRENT_BRANCH" != "main" ]; then
  exit 0
fi

# 檢查 upstream 是否是 origin/main
UPSTREAM_REF=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "")
if [ "$UPSTREAM_REF" != "origin/main" ]; then
  exit 0
fi

echo "Validating commits for push to 'main'..."

# 計算要推送的 commits：遠端 main 沒有的那些
# 使用本地的 refs/remotes/origin/main，避免連接 remote
if ! git rev-parse --verify --quiet refs/remotes/origin/main >/dev/null 2>&1; then
  # 遠端還沒有 main（第一次 push）：檢查所有 commits
  RANGE="HEAD"
else
  # 一般情況：只檢查「遠端 main 沒有」的那段
  RANGE="refs/remotes/origin/main..HEAD"
fi

COMMITS=$(git rev-list "$RANGE" 2>/dev/null || true)
if [ -z "$COMMITS" ]; then
  echo "No new commits to validate."
  exit 0
fi

echo "Commits to validate:" >&2
git log --oneline "$RANGE" >&2

# 強制套用 main branch 的規則
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
