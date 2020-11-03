#!/usr/bin/env bash
#----------------------------------------------------------
# deploy.sh
#
# This script should run in production only. It depends on
# the presence of underlying host conditions that are not
# practical to replicate in a development environment.
#----------------------------------------------------------

BASE_DIR=$1

# --------------------------------------------------------------------------
# function definitions
# --------------------------------------------------------------------------

function prepare_directories () {

  # This directory structure is based on the mount points
  # defined in the builder machine. The root represents
  # the base of the NFS public share.
  WEB_DIR=$1
  CONF_DIR="${WEB_DIR}-conf"
  OFFLINE_CONF_DIR="${WEB_DIR}-conf-offline"

  if [ ! -e "${WEB_DIR}" ]; then
    echo -e "Missing deployment directory ${WEB_DIR}"
    exit 1
  fi

  if [ ! -e "${CONF_DIR}" ]; then
    echo -e "Missing deployment directory ${CONF_DIR}"
    exit 1
  fi

  if [ ! -e "${OFFLINE_CONF_DIR}" ]; then
    echo -e "Missing deployment directory ${OFFLINE_CONF_DIR}"
    exit 1
  fi

  WEB_DIRS=('blue' 'green')

  for d in ${WEB_DIRS[@]}; do
    if [ ! -e ${WEB_DIR}/${d} ]; then
      mkdir -p ${WEB_DIR}/${d}
    fi
  done


}

function identify_live_config () {

  # identify which configuration is live (blue or green) or initialize first time
  if [ -e "${CONF_DIR}/default.conf" ]; then
    LIVE_LINK=$(ls -l "${CONF_DIR}/default.conf" | awk '{print $11}')
    LIVE_CONFIG=$(basename ${LIVE_LINK})
  else
    LIVE_CONFIG="blue"
  fi

  # define associative array to toggle between blue and green configs
  declare -A NEXT_CONFIG
  NEXT_CONFIG=([green]=blue [blue]=green)

  # identify the opposite config string (blue or green)
  IDLE_CONFIG=${NEXT_CONFIG[$LIVE_CONFIG]}

}

function deploy_files () {
  # rsync the build to NFS share idle side
  rsync -a "${BASE_DIR}/build/" "${WEB_DIR}/${IDLE_CONFIG}/"
}

function toggle_live_config () {

  # update the nginx config files just in case they have to change
  rsync -a "${BASE_DIR}/config/" "${CONF_DIR}/"
  rsync -a "${BASE_DIR}/config/" "${OFFLINE_CONF_DIR}/"

  # change the live link for the next reload of nginx
  rm "${CONF_DIR}/default.conf" > /dev/null 2>&1
  sh -c "cd ${CONF_DIR} && ln -s ${DESIRED_LIVE} default.conf"

  # change the offline nginx config too
  rm "${OFFLINE_CONF_DIR}/default.conf" > /dev/null 2>&1
  sh -c "cd ${OFFLINE_CONF_DIR} && ln -s ${LIVE_CONFIG} default.conf"

  # signal the celery job (it's watching for echoed messages)
  # to enable the currently idle side. Note: if no messages
  # is sent the configuration remains in its present state.
  echo -e "Enable: ${DESIRED_LIVE}"

}

# --------------------------------------------------------------------------
# live logic
# --------------------------------------------------------------------------

prepare_directories ${BASE_DIR}
identify_live_config
deploy_files
toggle_live_config
