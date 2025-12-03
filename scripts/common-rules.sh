#!/usr/bin/env bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[1;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# All allowed types, including wip for feature branches
COMMIT_TYPES="feat|fix|test|docs|style|chore|refactor|wip"
# Types for main branch, excluding wip
MAIN_COMMIT_TYPES="feat|fix|test|docs|style|chore|refactor"

# Task ID format, e.g., PROJ-1234
TASK_ID_PATTERN="[A-Z]+-[0-9]+"

# --- Rules for Main Branch ---
# On main branch, only below formats are allowed:
# 1. <TYPE>(PROJ-1234): <message>
# 2. <TYPE>(PROJ-1234,PROJ-5678): <message>
# 3. hotfix: <message>
MAIN_SCOPE_PATTERN="\(${TASK_ID_PATTERN}(,${TASK_ID_PATTERN})*\)"
MAIN_PATTERN="^(${MAIN_COMMIT_TYPES})${MAIN_SCOPE_PATTERN}: .+|hotfix: .+"

# --- Rules for Other Branches ---
# Task ID is optional
# 1. <TYPE>: <message>
# 2. <TYPE>(PROJ-1234): <message>
OTHER_PATTERN="^(${COMMIT_TYPES})(\\(${TASK_ID_PATTERN}\\))?: .+"

# Get current branch, fallback to commit hash if not on a branch
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD)

print_general_info() {
  local message=$1

  echo -e "┌──────────────────────────────┐"
  echo -e "│     Commit Message Format    │"
  echo -e "└──────────────────────────────┘"

  echo -e "${RED}❌ Your commit message is invalid${NC}"
  echo -e "\n"
  echo -e "${YELLOW}Current branch:${NC} ${GREEN}$CURRENT_BRANCH${NC}"
  echo -e "\n"
  echo -e "${YELLOW}Commit message:${NC} ${GREEN}$message${NC}"
  echo -e "\n"
}

print_readme_reminder() {
  echo -e "${YELLOW}For more info, see the README.md file.${NC}"
  echo -e "\n"
}

print_main_error() {
  local message=$1

  print_general_info "$message"
  echo -e "${YELLOW}On the main branch, required formats are:${NC}"
  echo -e "  1. ${BLUE}<TYPE>(PROJ-1234): <message>${NC}"
  echo -e "  2. ${BLUE}<TYPE>(PROJ-1234,PROJ-5678): <message>${NC}"
  echo -e "  3. ${BLUE}hotfix: <message>${NC}"
  echo -e "\n"
  print_readme_reminder
}

print_other_error() {
  local message=$1

  print_general_info "$message"
  echo -e "${YELLOW}On this branch, required formats are:${NC}"
  echo -e "  1. ${BLUE}<TYPE>: <message>${NC}"
  echo -e "  2. ${BLUE}<TYPE>(PROJ-1234): <message>${NC}"
  echo -e "\n"
  echo -e "${YELLOW}Where type is one of:${NC} ${BLUE}$COMMIT_TYPES${NC}"
  echo -e "\n"
  print_readme_reminder
}

validate_commit_message() {
  local message=$1

  if [ "$CURRENT_BRANCH" = "main" ]; then
    if [[ ! $message =~ $MAIN_PATTERN ]]; then
      print_main_error "$message"
      return 1
    fi
  else
    if [[ ! $message =~ $OTHER_PATTERN ]]; then
      print_other_error "$message"
      return 1
    fi
  fi
  return 0
}
