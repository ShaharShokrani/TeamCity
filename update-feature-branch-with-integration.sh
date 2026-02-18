#!/usr/bin/env bash
# Update a feature/bug/task branch with latest integration (rebase only).
# Used by TeamCity "Update feature branch with integration" build.
# Succeeds only when there are no conflicts; on conflict the build fails
# and the dev team must resolve manually (rebase onto integration locally).

set -euo pipefail

BRANCH_NAME="${1:?Usage: $0 <branch-name>}"

REMOTE=origin
INTEGRATION_BRANCH=integration

echo "Rebasing branch '${BRANCH_NAME}' onto '${REMOTE}/${INTEGRATION_BRANCH}'"
git branch -a

# Ensure we're on the right branch and clean
git checkout "${BRANCH_NAME}"
git status -sb

# Fetch latest integration (no checkout of integration needed)
git fetch "${REMOTE}" "${INTEGRATION_BRANCH}"

if ! git rebase "${REMOTE}/${INTEGRATION_BRANCH}"; then
  echo "ERROR: Rebase had conflicts. Aborting rebase. Resolve conflicts manually (rebase ${BRANCH_NAME} onto ${INTEGRATION_BRANCH} locally) and push."
  git rebase --abort
  exit 1
fi

# Fail the push if remote moved (e.g. dev pushed); do not overwrite—dev machines are source of truth.
echo "Rebase succeeded. Pushing (force-with-lease)..."
git push --force-with-lease "${REMOTE}" "${BRANCH_NAME}"

echo "Done. Branch '${BRANCH_NAME}' is now rebased onto '${INTEGRATION_BRANCH}'."
