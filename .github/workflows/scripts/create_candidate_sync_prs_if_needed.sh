#!/usr/bin/env bash
set -euo pipefail

git fetch --prune origin

: "${SOURCE_BRANCH:?SOURCE_BRANCH is required}"
: "${SOURCE_TAG:?SOURCE_TAG is required}"
: "${SOURCE_SHA:?SOURCE_SHA is required}"
: "${TRQS:?TRQS is required}"

case "$SOURCE_BRANCH" in
  release/*)
    CANDIDATE_TYPE="release"
    VERSION="${SOURCE_BRANCH#release/}"
    ;;
  hotfix/*)
    CANDIDATE_TYPE="hotfix"
    VERSION="${SOURCE_BRANCH#hotfix/}"
    ;;
  *)
    echo "::error title=Unsupported source branch::SOURCE_BRANCH must match release/* or hotfix/*, got: $SOURCE_BRANCH"
    exit 1
    ;;
esac

echo "Using source branch: $SOURCE_BRANCH"
echo "Using source tag: $SOURCE_TAG"
echo "Using source sha: $SOURCE_SHA"
echo "Candidate type: $CANDIDATE_TYPE"

if ! git cat-file -e "${SOURCE_SHA}^{commit}" 2>/dev/null; then
  echo "::error title=Missing source SHA::Commit $SOURCE_SHA does not exist"
  exit 1
fi

SYNC_BRANCH="sync/${CANDIDATE_TYPE}/${VERSION}/${TRQS}"

echo "Preparing sync branch: $SYNC_BRANCH"

if git ls-remote --exit-code --heads origin "$SYNC_BRANCH" >/dev/null 2>/dev/null; then
  echo "::notice title=Sync branch exists::Branch $SYNC_BRANCH already exists on remote"
else
  git branch -f "$SYNC_BRANCH" "$SOURCE_SHA"
  git push origin "refs/heads/$SYNC_BRANCH"
  echo "::notice title=Sync branch created::Created $SYNC_BRANCH at $SOURCE_SHA"
fi

FINAL_TAG="v${VERSION}"

title_for() {
  local base_branch="$1"
  echo "Sync ${SOURCE_BRANCH} (${SOURCE_TAG}) to ${base_branch} after CTMS import"
}

body_for() {
  cat <<EOF
Automatic PR created as sync merge-back after CTMS import to PRD.

---
CANDIDATE_TYPE: ${CANDIDATE_TYPE}
ORIGINAL_SOURCE_BRANCH: ${SOURCE_BRANCH}
DEPLOYED_SOURCE_TAG: ${SOURCE_TAG}
DEPLOYED_SOURCE_SHA: ${SOURCE_SHA}
SYNC_BRANCH: ${SYNC_BRANCH}
TAG: ${FINAL_TAG}
TRQS: ${TRQS}
EOF
}

create_pr_if_needed() {
  local base_branch="$1"
  local commits_ahead
  local existing
  local title
  local body
  local output

  if ! git show-ref --verify --quiet "refs/remotes/origin/$base_branch"; then
    echo "::error title=Missing base branch::Base branch $base_branch does not exist on origin"
    exit 1
  fi

  commits_ahead=$(git rev-list --count "origin/$base_branch..$SOURCE_SHA")

  if [ "$commits_ahead" -eq 0 ]; then
    echo "::notice title=No PR needed::No deployed commits to sync from $SOURCE_SHA to $base_branch"
    return 0
  fi

  existing=$(gh pr list \
    --state open \
    --base "$base_branch" \
    --head "$SYNC_BRANCH" \
    --json number \
    --jq 'length')

  if [ "$existing" -gt 0 ]; then
    echo "::warning title=PR already exists::Open PR from $SYNC_BRANCH to $base_branch already exists"
    return 0
  fi

  title="$(title_for "$base_branch")"
  body="$(body_for)"

  echo "Creating PR from $SYNC_BRANCH to $base_branch"

  if ! output=$(gh pr create \
    --base "$base_branch" \
    --head "$SYNC_BRANCH" \
    --title "$title" \
    --body "$body" 2>&1); then
    echo "::error title=PR creation failed::Failed to create PR from $SYNC_BRANCH to $base_branch"
    echo "$output"
    exit 1
  fi

  echo "::notice title=PR created::PR created from $SYNC_BRANCH to $base_branch, output: $output"
}

create_pr_if_needed "main"
create_pr_if_needed "dev"