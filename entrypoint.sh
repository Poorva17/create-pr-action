#!/bin/sh

set -eu

REPOSITORY=$GITHUB_REPOSITORY
CURRENT_BRANCH=${GITHUB_REF##*/}
HEAD_BRANCH=${HEAD_BRANCH:-release}
BASE_BRANCH=${BASE_BRANCH:-main}

CREATE_PR_URL=https://api.github.com/repos/$REPOSITORY/pulls

echo "::info::Configuration"
echo "::info:: CURRENT_BRANCH $CURRENT_BRANCH"
echo "::info:: HEAD_BRANCH $HEAD_BRANCH"
echo "::info:: BASE_BRANCH $BASE_BRANCH"
echo "::info:: if CURRENT_BRANCH is HEAD_BRANCH and is ahead of BASE_BRANCH, this action creates PR from CURRENT_BRANCH/HEAD_BRANCH against BASE_BRANCH"
echo "::info:: This action helps in keeping two branches in sync by auto creating PR"

check_create_PR_response() {
    ERROR="$1"
    if [ "$ERROR" != null ]; then
      PR_EXISTS=$(echo "${ERROR}" | jq 'select(. | contains("A pull request already exists for"))')
      if [ "$PR_EXISTS" != null ]; then
        echo "::info:: PR exists from $CURRENT_BRANCH against $BASE_BRANCH"
        exit 0
      else
        echo "::ERROR:: Error in creating PR from $CURRENT_BRANCH against $BASE_BRANCH: $ERROR "
        exit 1
      fi
    fi
}

if [ "$CURRENT_BRANCH" = "$HEAD_BRANCH" ]; then
  echo "::info:: creating PR for $CREATE_PR_URL from $CURRENT_BRANCH against $BASE_BRANCH"

  GIT_CREATE_PR_RESPONSE=$(
    curl \
      -X POST \
      -H "Accept: application/vnd.github.v3+json" \
      -H "Authorization: token $GITHUB_TOKEN" \
      "$CREATE_PR_URL" \
      -d "{\"head\":\"$CURRENT_BRANCH\",\"base\":\"$BASE_BRANCH\", \"title\": \"Merge $CURRENT_BRANCH into $BASE_BRANCH\"}"
  )
    ERROR_MSG=$(echo "${GIT_CREATE_PR_RESPONSE}" | jq '.errors[0].message')
    check_create_PR_response "$ERROR_MSG"

    PR_URL=$(echo "${GIT_CREATE_PR_RESPONSE}" | jq '.url'| tr -d \")

    echo "::info:: PR created successfully $PR_URL"
    CHANGED_FILES=$(echo "${GIT_CREATE_PR_RESPONSE}" | jq '.changed_files')

    if [ "$CHANGED_FILES" = 0 ]; then
      echo "::debug:: PR has 0 files changes, hence closing the PR $PR_URL"
      GIT_CLOSE_PR_RESPONSE=$(
        curl \
          -X PATCH \
          -H "Accept: application/vnd.github.v3+json" \
          -H "Authorization: token $GITHUB_TOKEN" \
          "$PR_URL" \
          -d '{"state":"closed", "title": "PR closed as 0 file changes"}'
      )
      echo "::info:: PR auto closed as $BASE_BRANCH is up-to-date with $CURRENT_BRANCH"
    else
      echo "::info:: PR created successfully $PR_URL"
    fi
fi
