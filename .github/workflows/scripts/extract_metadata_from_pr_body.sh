#!/usr/bin/env bash
set -euo pipefail

: "${PR_BODY:?PR_BODY is required}"
: "${GITHUB_ENV:?GITHUB_ENV is required}"

extract_field() {
  local key="$1"
  printf '%s\n' "$PR_BODY" \
    | sed -n "s/^${key}: //p" \
    | head -n1 \
    | tr -d '\r' \
    | sed 's/[[:space:]]*$//'
}

CANDIDATE_TYPE=$(extract_field "CANDIDATE_TYPE")
ORIGINAL_SOURCE_BRANCH=$(extract_field "ORIGINAL_SOURCE_BRANCH")
DEPLOYED_SOURCE_TAG=$(extract_field "DEPLOYED_SOURCE_TAG")
DEPLOYED_SOURCE_SHA=$(extract_field "DEPLOYED_SOURCE_SHA")
SYNC_BRANCH=$(extract_field "SYNC_BRANCH")
TAG=$(extract_field "TAG")
TRQS=$(extract_field "TRQS")

if [ -z "${TAG:-}" ]; then
  echo "::error title=TAG not found::TAG not found in PR body"
  exit 1
fi

if [ -z "${TRQS:-}" ]; then
  echo "::error title=TRQS not found::TRQS not found in PR body"
  exit 1
fi

if [[ ! "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "::error title=Invalid TAG::Extracted TAG '$TAG' is not a valid final tag"
  exit 1
fi

RELEASE_NOTES=$(cat <<EOF
TYPE: ${CANDIDATE_TYPE}
SOURCE_BRANCH: ${ORIGINAL_SOURCE_BRANCH}
SOURCE_TAG: ${DEPLOYED_SOURCE_TAG}
SOURCE_SHA: ${DEPLOYED_SOURCE_SHA}
SYNC_BRANCH: ${SYNC_BRANCH}
TAG: ${TAG}
TRQS: ${TRQS}
EOF
)

echo "CANDIDATE_TYPE=$CANDIDATE_TYPE" >> "$GITHUB_ENV"
echo "ORIGINAL_SOURCE_BRANCH=$ORIGINAL_SOURCE_BRANCH" >> "$GITHUB_ENV"
echo "DEPLOYED_SOURCE_TAG=$DEPLOYED_SOURCE_TAG" >> "$GITHUB_ENV"
echo "DEPLOYED_SOURCE_SHA=$DEPLOYED_SOURCE_SHA" >> "$GITHUB_ENV"
echo "SYNC_BRANCH=$SYNC_BRANCH" >> "$GITHUB_ENV"
echo "TAG=$TAG" >> "$GITHUB_ENV"
echo "TRQS=$TRQS" >> "$GITHUB_ENV"
{
  echo "RELEASE_NOTES<<EOF"
  printf '%s\n' "$RELEASE_NOTES"
  echo "EOF"
} >> "$GITHUB_ENV"

echo "::notice title=Metadata extracted::Resolved TAG=$TAG, TRQS=$TRQS, SYNC_BRANCH=$SYNC_BRANCH"