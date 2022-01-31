#!/bin/bash
set -e

#
# login 
#
# TODO(add support for multiple registry providers): We need to extend this function to support multiple registry providers
login() {
  if [[ ${CONTAINER_REPO} == *dkr.ecr* ]]; then
    local REPO_DOMAIN=null REGION=us-east-1
    REPO_DOMAIN="$(echo "$CONTAINER_REPO" | cut -d "/" -f 1)"
    REGION="$(echo "$CONTAINER_REPO" | cut -d "." -f 4)"
    # Run docker login in pipe
    aws ecr get-login-password --region "${REGION}" | docker login --username AWS --password-stdin "${REPO_DOMAIN}"
  fi
}

#
# build "${dockerfile_path}"
#
build() {
  local CONTAINER_IMG_TAG="$1"
  local DOCKER_FILE="${2:-Dockerfile}"
  DOCKER_BUILDKIT=0 docker build --progress=plain \
    --build-arg VERSION="${APP_VERSION}" --build-arg REVISION="${APP_REVISION}" \
    -t "${CONTAINER_IMG_TAG}" \
    -f "${CONTAINER_DIR}""${DOCKER_FILE}" .
}

#
# push
#
push() {
  local CONTAINER_IMG_TAG="$1"
  if [[ "${PUSH_TO_REGISTRY}" == "true" ]]; then
    docker push "${CONTAINER_IMG_TAG}"
  else
    echo "(push = ${PUSH_TO_REGISTRY}) Docker push disabled by user, image will not pushed to the Registry"
  fi
}

#
# cleanup
#
cleanup() {
  if [[ ${CONTAINER_REPO} == *dkr.ecr* ]]; then
    local REPO_DOMAIN=null
    REPO_DOMAIN="$(echo "$CONTAINER_REPO" | cut -d "/" -f 1)"
    docker logout "$REPO_DOMAIN"
  fi
}

#
# run_cmd ${cmd} ${cmd_param1}
#
run_cmd() {
  echo ""
  echo ">>> ${1} in progress..."
  echo ">>>>> image: ${2}"
  echo ""

  "${1}" "${2}" "${3}"

  echo ""
  echo ">>> ${2} finished."
  echo ""
}

###################################################################
#               MAIN
###################################################################

# >>>>>>>  Initialization
# Input vars
REGISTRY_LOGIN=${1:-""}
PUSH_TO_REGISTRY=${2:-""}

# Static vars
# TODO(improve logic for finding app.conf): Currently we have locked config location in infra/app.conf, we need to expand this feature
# in order if someone wants to build something in folder_name/ and it has different registry from infra/app.conf.
APP_CONFIG_FILE="${GITHUB_WORKSPACE}/infra/app.conf"
CONTAINER_DIR="infra/"


main(){
 
  # Check if app.conf is available if not exit the script 
  if [[ -f "${APP_CONFIG_FILE}" ]]; then
    echo "Application Config detected! Loading parameters..."
    # shellcheck source=${GITHUB_WORKSPACE}/infra/app.conf
    source "${APP_CONFIG_FILE}"
  
  else

    echo ""
    echo "Application config is not available in ${APP_CONFIG_FILE}."
    echo ">>> STOPPING! <<<"
    echo ">>> STOPPING! <<<"
    echo ""
    exit 1
    
  fi


  # Check if CONTAINER_REPO is defined in ${APP_CONFIG_FILE}
  if [[ -z "${CONTAINER_REPO}" ]]; then
    echo "Docker root repository is not defined. Aborting docker operations."
    exit 1
  fi

  if [[ "${REGISTRY_LOGIN}" == "true" ]]; then
    run_cmd login
  fi

  if [[ ${CONTAINER_REPO} == *"{container_prefix}"* ]];then

      DOCKERFILES=$(cd "${CONTAINER_DIR}" || exit ; find * -name '*.Dockerfile')

      for FILE in ${DOCKERFILES[@]} ; do
        CONTAINER_IMG_TAG=$(create_container_tag "${FILE}")
        run_cmd build "${CONTAINER_IMG_TAG}" "${FILE}"
        run_cmd push "${CONTAINER_IMG_TAG}"
      done

  else
      CONTAINER_IMG_TAG="${CONTAINER_REPO}:${APP_VERSION}"
      run_cmd build "${CONTAINER_IMG_TAG}"
      run_cmd push "${CONTAINER_IMG_TAG}"
  fi

  run_cmd cleanup

}


create_container_tag(){
    local DOCKERFILE="$1"
    SERVICE_NAME="/${DOCKERFILE%.*}"
    CONTAINER_REPO=$(echo "${CONTAINER_REPO}" | cut -f1-2 -d "/")
    echo "${CONTAINER_REPO}${SERVICE_NAME}:${APP_VERSION}"
}

main