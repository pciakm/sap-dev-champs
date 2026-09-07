#!/usr/bin/env bash
set -euo pipefail

: "${PKG_VER:?PKG_VER is required}"
: "${BRANCH_TYPE:?BRANCH_TYPE is required}"
: "${GITHUB_OUTPUT:?GITHUB_OUTPUT is required}"

VERSION="${PKG_VER}"

# Tags allowed for:
# - *rc - release candidate
# - *hc - hotfix candidate
# only apply when last branch sha differs from last tag sha

if [ "$BRANCH_TYPE" = "release" ]; then
    TAG_PREFIX="v${VERSION}-rc"
    BRANCH="${BRANCH_TYPE}/${VERSION}"
elif [ "$BRANCH_TYPE" = "hotfix" ]; then
    TAG_PREFIX="v${VERSION}-hc"
    BRANCH="${BRANCH_TYPE}/${VERSION}"
else
    echo "::error title=Invalid branch type::BRANCH_TYPE must be release | hotfix"
    exit 1
fi

git fetch --prune --tags origin

LAST_BRANCH_SHA=$(git rev-parse "origin/${BRANCH}")
LAST_TAG=$(git tag -l "${TAG_PREFIX}*" | sort -V | tail -1)

if [ -z "${LAST_TAG}" ]; then
    NEXT_NO=1
else
    LAST_NO=$(echo "${LAST_TAG}" | sed -En "s/^${TAG_PREFIX}([0-9]+)$/\1/p")
    LAST_TAG_SHA=$(git rev-parse "${LAST_TAG}")

    if [ "${LAST_BRANCH_SHA}" = "${LAST_TAG_SHA}" ]; then
        echo "::error title=No changes applied::No changes on branch ${BRANCH} since last tag ${LAST_TAG} with sha ${LAST_TAG_SHA}, please apply changes first"
        exit 1
    fi

    NEXT_NO=$((LAST_NO + 1))
fi

CANDIDATE_TAG="${TAG_PREFIX}${NEXT_NO}"
BRANCH_SHA="${LAST_BRANCH_SHA}"

if git rev-parse -q --verify "refs/tags/${CANDIDATE_TAG}" >/dev/null 2>/dev/null; then
    echo "::error title=Tag exists::Tag ${CANDIDATE_TAG} already exists locally"
    exit 1
fi

if git ls-remote --exit-code --tags origin "refs/tags/${CANDIDATE_TAG}" >/dev/null 2>/dev/null; then
    echo "::error title=Tag exists::Candidate tag ${CANDIDATE_TAG} already exists on remote"
    exit 1
fi

git tag "${CANDIDATE_TAG}" "${BRANCH_SHA}"
git push origin "${CANDIDATE_TAG}"

echo "::notice title=Tag created::Created candidate tag ${CANDIDATE_TAG} for ${BRANCH_SHA}"

echo "active_branch=${BRANCH}" >> "$GITHUB_OUTPUT"
echo "active_branch_sha=${BRANCH_SHA}" >> "$GITHUB_OUTPUT"
echo "candidate_tag=${CANDIDATE_TAG}" >> "$GITHUB_OUTPUT"