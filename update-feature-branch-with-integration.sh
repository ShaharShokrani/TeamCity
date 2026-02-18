#!/usr/bin/env bash
# Rebase source branch onto target branch and push (source = branch to update, target = base).
# Used by TeamCity "Update feature branch with integration" build.
# Succeeds only when there are no conflicts; on conflict the build fails
# and the dev team must resolve manually (rebase source onto target locally).

set -euo pipefail

SOURCE_BRANCH="${1:?Usage: $0 <source-branch> <target-branch>}"
TARGET_BRANCH="${2:?Usage: $0 <source-branch> <target-branch>}"

REMOTE=origin

echo "Rebasing source '${SOURCE_BRANCH}' onto target '${REMOTE}/${TARGET_BRANCH}'"
git branch -a

# Fetch both branches so they exist (agent may only have default branch)
git fetch "${REMOTE}" "${SOURCE_BRANCH}" "${TARGET_BRANCH}"

# Clean working tree so checkout is not blocked by local changes (e.g. script on main differs from branch)
git reset --hard HEAD
git clean -fd

# Ensure we're on the source branch (create/update from remote)
git checkout -B "${SOURCE_BRANCH}" "${REMOTE}/${SOURCE_BRANCH}"
git status -sb

if ! git rebase "${REMOTE}/${TARGET_BRANCH}"; then
  echo "ERROR: Rebase had conflicts. Aborting rebase. Resolve conflicts manually (rebase ${SOURCE_BRANCH} onto ${TARGET_BRANCH} locally) and push."
  git rebase --abort
  exit 1
fi

# Fail the push if remote moved (e.g. dev pushed); do not overwrite—dev machines are source of truth.
echo "Rebase succeeded. Pushing (force-with-lease)..."
git push --force-with-lease "${REMOTE}" "${SOURCE_BRANCH}"

echo "Done. Branch '${SOURCE_BRANCH}' is now rebased onto '${TARGET_BRANCH}'."
