#!/usr/bin/env bash
set -euo pipefail

git fetch --prune --tags origin

if [ -z "${TRQS:-}" ]; then
  echo "::error title=Missing transport id::TRQS is empty"
  exit 1
fi

if [[ "$TRQS" == *-* ]]; then
  echo "::error title=Multiple transports not supported::Expected exactly one transport id, got: $TRQS"
  exit 1
fi

TRANSPORT_ID="$TRQS"
echo "Looking for metadata tag for transport: $TRANSPORT_ID"

mapfile -t MATCHING_TAGS < <(git tag -l "ctms-export/${TRANSPORT_ID}")

if [ "${#MATCHING_TAGS[@]}" -eq 0 ]; then
  echo "::error title=Transport metadata not found::No git tag metadata found for transport $TRANSPORT_ID"
  exit 1
fi

if [ "${#MATCHING_TAGS[@]}" -gt 1 ]; then
  echo "::error title=Ambiguous transport metadata::More than one metadata tag found for transport $TRANSPORT_ID"
  printf ' - %s\n' "${MATCHING_TAGS[@]}"
  exit 1
fi

TAG_NAME="${MATCHING_TAGS[0]}"
echo "Matched metadata tag: $TAG_NAME"

TAG_MESSAGE="$(git for-each-ref "refs/tags/${TAG_NAME}" --format='%(contents)')"

if [ -z "$TAG_MESSAGE" ]; then
  echo "::error title=Empty metadata::Tag $TAG_NAME has empty message"
  exit 1
fi

SOURCE_BRANCH="$(echo "$TAG_MESSAGE" | jq -r '.source_branch')"
BRANCH_TYPE="$(echo "$TAG_MESSAGE" | jq -r '.branch_type')"
SOURCE_VERSION="$(echo "$TAG_MESSAGE" | jq -r '.source_version // empty')"
SOURCE_TAG="$(echo "$TAG_MESSAGE" | jq -r '.source_tag')"
SOURCE_SHA="$(echo "$TAG_MESSAGE" | jq -r '.source_sha')"

echo "Resolved source_branch=$SOURCE_BRANCH"
echo "Resolved branch_type=$BRANCH_TYPE"
echo "Resolved source_version=$SOURCE_VERSION"
echo "Resolved source_tag=$SOURCE_TAG"
echo "Resolved source_sha=$SOURCE_SHA"

echo "source_branch=$SOURCE_BRANCH" >> "$GITHUB_OUTPUT"
echo "branch_type=$BRANCH_TYPE" >> "$GITHUB_OUTPUT"
echo "source_version=$SOURCE_VERSION" >> "$GITHUB_OUTPUT"
echo "source_tag=$SOURCE_TAG" >> "$GITHUB_OUTPUT"
echo "source_sha=$SOURCE_SHA" >> "$GITHUB_OUTPUT"
