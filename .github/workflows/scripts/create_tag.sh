#!/usr/bin/env bash
set -euo pipefail

: "${TAG:?TAG is required}"

git fetch --prune --tags origin
git checkout -B main origin/main

if git rev-parse -q --verify "refs/tags/$TAG" >/dev/null 2>/dev/null; then
    echo "::notice title=TAG exists::Tag $TAG already exists locally"
    exit 0
fi

if git ls-remote --exit-code --tags origin "refs/tags/$TAG" >/dev/null 2>/dev/null; then
    echo "::notice title=TAG exists::Tag $TAG already exists on remote"
    exit 0
fi

git tag "$TAG"
git push origin "$TAG"

echo "::notice title=TAG created::Tag $TAG created and pushed"
