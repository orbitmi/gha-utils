#!/bin/bash

set -o errexit
set -o nounset

########
# Variable
####
RELEASE_TYPE="${1:-none}"
DRYRUN_ENABLED="${DRY_RUN:+yes}"

LATEST_HEAD_SHA=$(git rev-parse HEAD)
PREVIOUS_RELEASE_TAG=$(git describe --tags --abbrev=0 --match="*.*.*" "$(git rev-list --tags --max-count=1)" || echo "0.0.0")
LATEST_TAG_SHA=$(git rev-list -n 1 "$PREVIOUS_RELEASE_TAG" || echo "$LATEST_HEAD_SHA")

#######
# Functions
####

function fail {
    printf '%s\n' "$1" >&2 ## Send message to stderr.
    exit "${2:-1}" ## Return a code specified by $2, or 1 by default.
}

init_git() {
    git config --local user.name "${GIT_USER_NAME:-github-actions}"
    git config --local user.email "${GIT_USER_EMAIL:-41898282+github-actions[bot]@users.noreply.github.com}"
}

set_var() {
    KEY="${1}"
    VAL="${2}"

    export "${KEY}=${VAL}"
    # shellcheck disable=SC2086
    echo "${KEY}=${VAL}" >> $GITHUB_ENV
    echo "${KEY}=${VAL}" >> $GITHUB_OUTPUT
    echo ">>> New variable exported [ ${KEY} = ${VAL} ]"
}

#
# increment_version "${latest_release_tag}" "${release_type}
# example:
#     $(increase_version '1.2.3' 'minor') => 1.3.0
increment_version() {
  mapfile -t VERSION < <(echo "${1}" | tr "." "\n")
  local RELEASE_TYPE=${2}

  if [[ ${#VERSION[@]} -ne 3 ]]; then
    echo "TAG [${1}] is not in semantic versioning format"
    exit 1
  else
    if [[ "$RELEASE_TYPE" == "major" ]]; then
      ((VERSION[0]++))
      VERSION[1]=0
      VERSION[2]=0
    fi
    if [[ "$RELEASE_TYPE" == "minor" ]]; then
      ((VERSION[1]++))
      VERSION[2]=0
    fi
    if [[ "$RELEASE_TYPE" == "patch" ]]; then ((VERSION[2]++)); fi

    echo "${VERSION[0]}.${VERSION[1]}.${VERSION[2]}"
  fi
}

#
#
#
get_checkout_sha() {
  local SHA
  if [[ "$RELEASE_TYPE" == "patch" ]]; then
    SHA=${LATEST_TAG_SHA}
  else
    SHA=${LATEST_HEAD_SHA}
  fi
  echo "${SHA}"
}

release_branch_exists() {
  if git branch -r | grep -q "release/${1}"; then echo "true"; else echo "false"; fi
}

#
# create_release_branch "${previous_release_tag}" "${release_type}
# example:
#     $(create_release_branch '1.2.3' 'minor') => (new branch) 1.3.0
# shellcheck disable=SC2155
create_release_branch() {
  local NEW_VERSION=$(increment_version "${1}" "${2}")
  local CHECKOUT_SHA=$(get_checkout_sha "${2}")
  local RELEASE_BRANCH="release/${NEW_VERSION}"

  set_var "new_version" "${NEW_VERSION}"
  set_var "checkout_sha" "${CHECKOUT_SHA}"

  if [[ "$(release_branch_exists "${NEW_VERSION}")" == "true" ]]; then
    fail "Release branch '${RELEASE_BRANCH}' already exists, we can't create new one!"
  fi

  SWITCH_CMD="git switch -c ${RELEASE_BRANCH} ${CHECKOUT_SHA}"

  if [[ "${DRYRUN_ENABLED}" == "yes" ]]; then
    echo ">>>> DRY RUN"
    echo "${SWITCH_CMD}"
  else
    eval "${SWITCH_CMD}"
  fi
}

push_changes() {
    local PUSH_CMD="git push --set-upstream origin $(git branch --show-current)"
    if [[ "${DRYRUN_ENABLED}" == "yes" ]]; then
      echo ">>>> DRY RUN"
      echo "${PUSH_CMD}"
    else
      echo ">>>Checking a git status before push"
      git status

      eval "${PUSH_CMD}"
    fi
}

#######
# MAIN
####

init_git
# Create release branch based on the last release tag and submitted release type
create_release_branch "$PREVIOUS_RELEASE_TAG" "$RELEASE_TYPE"

push_changes
