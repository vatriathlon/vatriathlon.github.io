#!/bin/bash
set -e

echo "SOURCE_DIR: ${SOURCE_DIR}"

## Generated folder must exist
if [ ! -d "$SOURCE_DIR" ]; then
  echo "SOURCE_DIR (${SOURCE_DIR}) does not exist, build the source directory before deploying"
  exit 1
fi

## Prevent publish on tags
CURRENT_TAG=$(git tag --contains HEAD)
echo "STOP_PUBLISH: ${STOP_PUBLISH}"
echo "CURRENT_TAG: ${CURRENT_TAG}"
echo "TRAVIS_OS_NAME: $TRAVIS_OS_NAME"
echo "TRAVIS_BRANCH: ${TRAVIS_BRANCH}"
echo "BUILD_BRANCH: ${BUILD_BRANCH}"
echo "TRAVIS_PULL_REQUEST: ${TRAVIS_PULL_REQUEST}"

if [ -z "${STOP_PUBLISH}" ] && [ "$TRAVIS_OS_NAME" = "linux" ] && [ "$TRAVIS_BRANCH" = "$BUILD_BRANCH" ] && [ -z "$CURRENT_TAG" ] && [ "$TRAVIS_PULL_REQUEST" = "false" ]
then
  echo 'Publishing...'
else
  echo 'Skipping publishing'
  exit 0
fi


SSH_KEY_NAME="travis_rsa"

## Git configuration
git config --global user.email ${USER_EMAIL}
git config --global user.name "${USER_NAME}"

## Repository URL
GIT_REPOSITORY=$(git config remote.origin.url)
GIT_REPOSITORY=${GIT_REPOSITORY/git:\/\/github.com\//git@github.com:}".git"
GIT_REPOSITORY=${GIT_REPOSITORY/git:\/\/github.com\//git@github.com:}
GIT_REPOSITORY=${GIT_REPOSITORY/https:\/\/github.com\//git@github.com:}

echo "REPO: ${GIT_REPOSITORY}"

REVISION=$(git rev-parse HEAD)

## Create deploy content directory
REPO_NAME=$(basename $GIT_REPOSITORY)
TARGET_DIR=$(mktemp -d /tmp/$REPO_NAME.XXXX)

echo "TARGET_DIR: ${TARGET_DIR}"

git clone --branch "${DEPLOY_BRANCH}" "${GIT_REPOSITORY}" "${TARGET_DIR}"

## Copy public content
rsync -rt --delete --exclude=".git" "${SOURCE_DIR}/" "${TARGET_DIR}/"

cd $TARGET_DIR

## Add content
git add -A

## Commit and push if mandatory
if git diff --quiet --exit-code --cached
then
  echo 'No change'
else
  git commit -m "Publish from $REVISION"
  git push --follow-tags origin ${DEPLOY_BRANCH}
fi

