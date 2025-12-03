#!/usr/bin/env bash

# Source the common rules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common-rules.sh"

# Color definitions (if not already defined in common-rules.sh)
RED='\033[0;31m'
GREEN='\033[1;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔍 Pre-push hook triggered${NC}" >&2

# Read push information from stdin
while read local_ref local_sha remote_ref remote_sha
do
  echo -e "${BLUE}DEBUG: local_ref=$local_ref${NC}" >&2
  echo -e "${BLUE}DEBUG: local_sha=$local_sha${NC}" >&2
  echo -e "${BLUE}DEBUG: remote_ref=$remote_ref${NC}" >&2
  echo -e "${BLUE}DEBUG: remote_sha=$remote_sha${NC}" >&2
  # Get the branch name being pushed
  BRANCH_NAME=$(echo "$local_ref" | sed 's/refs\/heads\///')
  
  # Only check main branch
  if [ "$BRANCH_NAME" != "main" ]; then
    echo -e "${BLUE}ℹ️  Skipping pre-push validation for branch: $BRANCH_NAME${NC}"
    continue
  fi
  
  echo -e "${YELLOW}🔍 Validating commits on main branch before push...${NC}"
  
  # If remote_sha is all zeros, it means we're pushing to a new branch
  if [ "$remote_sha" = "0000000000000000000000000000000000000000" ]; then
    # Get all commits in the branch
    COMMITS=$(git rev-list "$local_sha")
  else
    # Get commits that exist locally but not on remote
    COMMITS=$(git rev-list "$remote_sha..$local_sha")
  fi
  
  # Check if there are any commits to validate
  if [ -z "$COMMITS" ]; then
    echo -e "${GREEN}✅ No new commits to validate${NC}"
    continue
  fi
  
  # Validate each commit message
  INVALID_COMMITS=()
  while IFS= read -r commit; do
    MESSAGE=$(git log -1 --pretty=%B "$commit")
    
    # Override CURRENT_BRANCH to "main" for validation
    CURRENT_BRANCH="main"
    
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
done

exit 0
