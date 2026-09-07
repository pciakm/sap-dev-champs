#!/usr/bin/env bash
set -euo pipefail

: "${BRANCH_TYPE:?BRANCH_TYPE is required}"

if [ -n "${CANDIDATE_TAG:-}" ]; then
    if [ "$BRANCH_TYPE" = "release" ]; then
        TAG_REGEX='^v[0-9]+\.[0-9]+\.[0-9]+-rc[0-9]+$'
    elif [ "$BRANCH_TYPE" = "hotfix" ]; then
        TAG_REGEX='^v[0-9]+\.[0-9]+\.[0-9]+-hc[0-9]+$'            
    fi

    if [[ ! "$CANDIDATE_TAG" =~ $TAG_REGEX ]]; then
        echo "::error title=Invalid tag::Tag $CANDIDATE_TAG does not match format for $BRANCH_TYPE. Expected is vX.Y.Z-rcN (for release branch) and vX.Y.Z-hcN (for hotfix branch)."
        exit 1
    fi          
    echo "::notice title=Tag format valid::Tag format $CANDIDATE_TAG is valid for $BRANCH_TYPE"
else
    echo "::notice title=Tag not provided::Tag not provided, the last tag for the active ${BRANCH_TYPE} branch version will be used."
fi
