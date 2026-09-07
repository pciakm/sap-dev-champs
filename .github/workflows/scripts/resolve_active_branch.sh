#!/usr/bin/env bash
set -euo pipefail

: "${BRANCH_TYPE:?BRANCH_TYPE is required}"

if [[ "$BRANCH_TYPE" != "release" && "$BRANCH_TYPE" != "hotfix" ]]; then
    echo "::error title=Invalid branch type::BRANCH_TYPE must be release or hotfix"
    exit 1
fi

git fetch --prune origin

mapfile -t MATCHING_BRANCHES < <(
  git for-each-ref --format='%(refname:short)' "refs/remotes/origin/${BRANCH_TYPE}/*" \
  | sed 's#^origin/##'
)

if [ "${#MATCHING_BRANCHES[@]}" -eq 0 ]; then
  echo "::error title=No active branch::No active ${BRANCH_TYPE}/* branch found"
  exit 1
elif [ "${#MATCHING_BRANCHES[@]}" -gt 1 ]; then
  echo "::error title=More than one active branch::More than one active ${BRANCH_TYPE}/* branch found"
  printf ' - %s\n' "${MATCHING_BRANCHES[@]}"
  exit 1
fi

ACTIVE_BRANCH="${MATCHING_BRANCHES[0]}"
VERSION="${ACTIVE_BRANCH#${BRANCH_TYPE}/}"

echo "active_branch=${ACTIVE_BRANCH}" >> "$GITHUB_OUTPUT"
echo "version=${VERSION}" >> "$GITHUB_OUTPUT"

echo "::notice title=Resolved active branch::Using branch ${ACTIVE_BRANCH}"
echo "::notice title=Resolved version::Using version ${VERSION}"