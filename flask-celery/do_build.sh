#!/usr/bin/env bash

git_host=$1       # git@gitolite
git_repository=$2 # pub/rjpw/web-example.git
git_commit=$3     # sha hash
git_ref=$4        # refs/heads/master

PROJECT_NAME=$(basename ${git_repository} .git)
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# clone project
if [ ! -e "${HOME}/src/${PROJECT_NAME}" ]; then
  cd ${HOME}/src && git clone ${git_host}:${git_repository} ${HOME}/src/${PROJECT_NAME} > /dev/null 2>&1
fi

function run_deployment_script () {
  if [ -e "${HOME}/src/${PROJECT_NAME}/live_deploy.sh" ]; then
    DEPLOY_VAL=$(bash "${HOME}/src/${PROJECT_NAME}/live_deploy.sh")
    echo -e ${DEPLOY_VAL}
  else
    SCRIPT_RESULT=$(sh -c "${THIS_DIR}/deploy.sh ${PROJECT_NAME}")
    echo -e ${SCRIPT_RESULT}
  fi
}

# run deployment script
if [ -e "${HOME}/src/${PROJECT_NAME}" ]; then
  cd ${HOME}/src/${PROJECT_NAME} && git pull > /dev/null 2>&1
  cd "${HOME}/src/${PROJECT_NAME}" && git checkout ${git_commit} > /dev/null 2>&1
  run_deployment_script
else
  echo -e "Unable to find project ${PROJECT_NAME}"
fi
