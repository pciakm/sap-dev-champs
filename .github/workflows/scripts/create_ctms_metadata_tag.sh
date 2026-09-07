#!/usr/bin/env bash
set -euo pipefail

: "${APP_NAME:?APP_NAME is required}"
: "${SOURCE_BRANCH:?SOURCE_BRANCH is required}"
: "${SOURCE_SHA:?SOURCE_SHA is required}"
: "${TRANSPORT_ID:?TRANSPORT_ID is required}"

case "$SOURCE_BRANCH" in
    release/*)
        BRANCH_TYPE="release"
        SOURCE_VERSION="${SOURCE_BRANCH#release/}"
        ;;
    hotfix/*)
        BRANCH_TYPE="hotfix"
        SOURCE_VERSION="${SOURCE_BRANCH#hotfix/}"
        ;;
    *)
        echo "::error title=Unsupported source branch::SOURCE_BRANCH must match release/* or hotfix/*, got: $SOURCE_BRANCH"
        exit 1
        ;;
esac

TAG_NAME="ctms-export/${TRANSPORT_ID}"

TAG_MESSAGE=$(jq -n \
  --arg transport_id "$TRANSPORT_ID" \
  --arg branch_type "$BRANCH_TYPE" \
  --arg source_branch "$SOURCE_BRANCH" \
  --arg source_version "$SOURCE_VERSION" \
  --arg source_tag "$SOURCE_TAG" \
  --arg source_sha "$SOURCE_SHA" \
  '{
    transport_id: $transport_id,
    branch_type: $branch_type,
    source_branch: $source_branch,
    source_version: $source_version,
    source_tag: $source_tag,
    source_sha: $source_sha    
  }')

echo "Creating metadata tag: $TAG_NAME"

git config user.name "${GITHUB_ACTOR}"            
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"

git fetch --prune --tags origin
git tag -a "$TAG_NAME" -m "$TAG_MESSAGE"
git push origin "$TAG_NAME"
