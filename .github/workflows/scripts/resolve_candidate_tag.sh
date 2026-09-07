#!/usr/bin/env bash
set -euo pipefail

: "${BRANCH_TYPE:?BRANCH_TYPE is required}"
: "${VERSION:?VERSION is required}"

git fetch --prune --tags origin

if [ "$BRANCH_TYPE" = "release" ]; then
  TAG_PREFIX="v${VERSION}-rc"
elif [ "$BRANCH_TYPE" = "hotfix" ]; then
  TAG_PREFIX="v${VERSION}-hc"
else
  echo "::error title=Invalid branch type::Branch type must be release or hotfix, current is ${BRANCH_TYPE}"
  exit 1
fi

echo "Looking for tag ${TAG_PREFIX}"

if [ -n "${CANDIDATE_TAG:-}" ]; then
  if ! git rev-parse -q --verify "refs/tags/$CANDIDATE_TAG" >/dev/null 2>/dev/null; then
    echo "::error title=Invalid candidate tag::Provided candidate tag $CANDIDATE_TAG does not exist"
    exit 1
  fi
else
  CANDIDATE_TAG=$(git tag -l "${TAG_PREFIX}*" | sort -V | tail -1)
fi

if [ -z "${CANDIDATE_TAG:-}" ]; then
  echo "::error title=Missing candidate tag::No candidate tag provided and no matching found for branch type ${BRANCH_TYPE}"
  exit 1
fi

CANDIDATE_TAG_SHA=$(git rev-parse "$CANDIDATE_TAG")
echo "candidate_tag_sha=$CANDIDATE_TAG_SHA" >> "$GITHUB_OUTPUT"
echo "candidate_tag=$CANDIDATE_TAG" >> "$GITHUB_OUTPUT"

echo "::notice title=Resolved candidate tag::Using candidate tag ${CANDIDATE_TAG}"
echo "::notice title=Candidate tag SHA::Candidate tag SHA is ${CANDIDATE_TAG_SHA}"