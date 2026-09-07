#!/usr/bin/env bash
set -euo pipefail

: "${TAG:?TAG is required}"
: "${GH_TOKEN:?GH_TOKEN is required}"
: "${RELEASE_NOTES:?RELEASE_NOTES is required}"

if gh release view "$TAG" >/dev/null 2>&1; then
  echo "::notice title=Release exists::Release $TAG already exists"
  exit 0
fi

gh release create "$TAG" \
  --title "$TAG" \
  --notes "$RELEASE_NOTES"

echo "::notice title=Release created::Release $TAG created"