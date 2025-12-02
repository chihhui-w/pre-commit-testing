#!/usr/bin/env bash

set -euo pipefail

# This script is used by pre-commit (commit-msg hook).
# It validates the subject line of the commit message.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/common-rules.sh"

if [ $# -eq 0 ]; then
  echo -e "${RED}Error: No commit message file provided to commit-msg hook${NC}"
  exit 1
fi

COMMIT_MSG_FILE=$1
COMMIT_MSG=$(head -n1 "$COMMIT_MSG_FILE" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

if [ -z "$COMMIT_MSG" ]; then
  echo -e "${RED}Error: Commit message is empty${NC}"
  exit 1
fi

if ! validate_commit_message "$COMMIT_MSG"; then
  exit 1
fi

exit 0


