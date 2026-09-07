#!/usr/bin/env bash
set -euo pipefail

: "${GH_TOKEN:?GH_TOKEN is required}"
: "${SYNC_BRANCH:?SYNC_BRANCH is required}"

echo "Source sync branch: $SYNC_BRANCH"

if [[ ! "$SYNC_BRANCH" =~ ^sync/(release|hotfix)/ ]]; then
  echo "Branch is not sync/release/* or sync/hotfix/*, skipping delete"
  exit 0
fi

OPEN_SYNC_PRS=$(gh pr list \
  --head "$SYNC_BRANCH" \
  --state open \
  --json number \
  --jq 'length')

if [ "$OPEN_SYNC_PRS" -gt 0 ]; then
  echo "::notice title=Sync branch not deleted::Open PRs still exist for $SYNC_BRANCH, skipping delete"
  exit 0
fi

PROCESS_BRANCH=""
if [[ "$SYNC_BRANCH" =~ ^sync/release/([0-9]+\.[0-9]+\.[0-9]+)/[^/]+$ ]]; then
  PROCESS_BRANCH="release/${BASH_REMATCH[1]}"
elif [[ "$SYNC_BRANCH" =~ ^sync/hotfix/([0-9]+\.[0-9]+\.[0-9]+)/[^/]+$ ]]; then
  PROCESS_BRANCH="hotfix/${BASH_REMATCH[1]}"
fi

echo "Resolved process branch: ${PROCESS_BRANCH:-<none>}"

git push origin --delete "$SYNC_BRANCH"

if [ -z "$PROCESS_BRANCH" ]; then
  echo "::notice title=Process branch not resolved::Could not resolve release/* or hotfix/* branch from $SYNC_BRANCH"
  exit 0
fi

OPEN_PROCESS_PRS=$(gh pr list \
  --head "$PROCESS_BRANCH" \
  --state open \
  --json number \
  --jq 'length')

if [ "$OPEN_PROCESS_PRS" -gt 0 ]; then
  echo "::notice title=Process branch not deleted::Open PRs still exist for $PROCESS_BRANCH, skipping delete"
  exit 0
fi

if git ls-remote --exit-code --heads origin "$PROCESS_BRANCH" >/dev/null 2>/dev/null; then
  git push origin --delete "$PROCESS_BRANCH"
  echo "::notice title=Branches deleted::Deleted $SYNC_BRANCH and $PROCESS_BRANCH"
else
  echo "::notice title=Process branch missing::Branch $PROCESS_BRANCH does not exist on remote, deleted only $SYNC_BRANCH"
fi