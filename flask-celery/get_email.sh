#!/usr/bin/env bash

git_repository=$1 # pub/rjpw/web-example.git
git_commit=$2     # sha hash

PROJECT_NAME=$(basename ${git_repository} .git)

if [ -e "${HOME}/src/${PROJECT_NAME}" ]; then
  AUTHOR_EMAIL=$(cd ${HOME}/src/${PROJECT_NAME} && git show -s --pretty=%ae ${git_commit})
  echo -e ${AUTHOR_EMAIL}
else
  echo -e "Unable to find project ${PROJECT_NAME}"
fi
