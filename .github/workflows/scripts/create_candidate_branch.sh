#!/usr/bin/env bash
set -euo pipefail

: "${BRANCH_TYPE:?BRANCH_TYPE is required}"
: "${PKG_VER:?PKG_VER is required}"

if [[ "$BRANCH_TYPE" != "release" && "$BRANCH_TYPE" != "hotfix" ]]; then
    echo "::error title=Invalid branch type::BRANCH_TYPE must be release or hotfix"
    exit 1
fi

VERSION="${PKG_VER}"
CANDIDATE_BRANCH="${BRANCH_TYPE}/${VERSION}"

if git ls-remote --exit-code --heads origin "${CANDIDATE_BRANCH}" >/dev/null 2>/dev/null; then
    echo "::notice title=Branch exists::Branch ${CANDIDATE_BRANCH} already exists, skipping creation" 
else
    echo "::notice title=Creating branch::Branch ${CANDIDATE_BRANCH} does not exist, creating it" 

    git config user.name "${GITHUB_ACTOR}"            
    git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
    
    git checkout "${GITHUB_REF_NAME}"
    git checkout -b "${CANDIDATE_BRANCH}"
    git push origin "${CANDIDATE_BRANCH}"

    echo "::notice title=Branch created::Created branch ${CANDIDATE_BRANCH}"
fi