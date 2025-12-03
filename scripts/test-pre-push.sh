#!/usr/bin/env bash

# Source the common rules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-rules.sh"

# Get current branch
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)

# Only check main branch
if [ "$CURRENT_BRANCH" != "main" ]; then
  echo -e "${BLUE}ℹ️  Skipping pre-push validation for branch: $CURRENT_BRANCH${NC}"
  exit 0
fi

echo -e "${YELLOW}🔍 Validating commits on main branch before push...${NC}"

# Get the remote tracking branch
REMOTE_BRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)

if [ -z "$REMOTE_BRANCH" ]; then
  echo -e "${YELLOW}⚠️  No remote tracking branch found, skipping validation${NC}"
  exit 0
fi

# Get commits that exist locally but not on remote
COMMITS=$(git rev-list "$REMOTE_BRANCH..HEAD")

# Check if there are any commits to validate
if [ -z "$COMMITS" ]; then
  echo -e "${GREEN}✅ No new commits to validate${NC}"
  exit 0
fi

# Validate each commit message
INVALID_COMMITS=()
while IFS= read -r commit; do
  MESSAGE=$(git log -1 --pretty=%B "$commit")
  
  if ! validate_commit_message "$MESSAGE"; then
    INVALID_COMMITS+=("$commit: $MESSAGE")
  fi
done <<< "$COMMITS"

# If there are invalid commits, reject the push
if [ ${#INVALID_COMMITS[@]} -gt 0 ]; then
  echo -e "\n${RED}❌ Push rejected: Found ${#INVALID_COMMITS[@]} invalid commit(s)${NC}\n"
  
  for invalid in "${INVALID_COMMITS[@]}"; do
    commit_hash=$(echo "$invalid" | cut -d: -f1)
    commit_msg=$(echo "$invalid" | cut -d: -f2-)
    echo -e "${RED}  • $commit_hash${NC}$commit_msg"
  done
  
  echo -e "\n${YELLOW}Please fix the commit messages and try again.${NC}"
  echo -e "${YELLOW}You can use 'git rebase -i' to edit commit messages.${NC}\n"
  exit 1
fi

echo -e "${GREEN}✅ All commits passed validation${NC}\n"
exit 0
