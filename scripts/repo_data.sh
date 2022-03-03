#!/bin/bash

set_var() {
    KEY="${1}"
    VAL="${2}"

    # https://trstringer.com/github-actions-multiline-strings/
    VAL="${VAL//'%'/'%25'}"
    VAL="${VAL//$'\n'/'%0A'}"
    VAL="${VAL//$'\r'/'%0D'}"

    export "${KEY}=${VAL}"
    # shellcheck disable=SC2086
    echo "${KEY}=${VAL}" >> $GITHUB_ENV
    echo "::set-output name=${KEY}::${VAL}"
}

resolve_app_version() {
    # If HEAD_REF is not NULL and Base branch doesn't contain 'pull' - then it's production
    if [[ -n "${GITHUB_HEAD_REF}" ]]; then
    	echo " >>> Pull Request Detected."
        if [[ -z "${GITHUB_REF##main}" ]] || [[ -z "${GITHUB_REF##master}" ]]; then
            set_var APP_RELEASE_TYPE "Production"
            set_var APP_VERSION "${GITHUB_HEAD_REF##release/}"
        fi
        if [[ -z "${GITHUB_REF##*/pull/*}" ]]; then
            set_var APP_RELEASE_TYPE "Beta (Pre-release)"
            set_var APP_VERSION "${GITHUB_HEAD_REF##release/}-rc.${GITHUB_RUN_NUMBER}"
        fi
    else
      if [[ -z "${GITHUB_REF##*main}" ]] || [[ -z "${GITHUB_REF##*master}" ]]; then
        set_var APP_RELEASE_TYPE "Alpha (Debug)"
        set_var APP_VERSION "alpha-${GITHUB_SHA::7}"
      fi
      if [[ -z "${GITHUB_REF##*/release/*}" ]]; then
        set_var APP_RELEASE_TYPE "Beta (Pre-release)"
        set_var APP_VERSION "${GITHUB_REF##refs/heads/release/}-rc.${GITHUB_RUN_NUMBER}"
      fi
      if [[ -z "${GITHUB_REF##*/tags/*}" ]]; then
        set_var APP_RELEASE_TYPE "Production"
        set_var APP_VERSION "${GITHUB_REF##refs/tags/}"
      fi
    fi
}

report() {
    echo "########"
    echo "# Repository Summary"
    echo "######"
    echo ""
    echo "Repository: ${APP_REPO}"
    echo "Repository name: ${APP_REPO_NAME}"
    echo "Organization name: ${APP_REPO_ORG}"
    echo "Revision: ${APP_REVISION}"
    echo "Branch ref: ${GITHUB_REF}"
    echo "Head Branch ref: ${GITHUB_HEAD_REF:-None}"
    echo "Release type: ${APP_RELEASE_TYPE}"
    echo "App Version: ${APP_VERSION}"
    echo "Container Repo: ${CONTAINER_REPO}"
    echo ""
    echo "######"
}

generate_repo_summary() {
  SUMMARY=$(cat <<END
🎉 Congrats! New version *${APP_VERSION}* is released and ready for deployment 🚀🚀🚀

<details>
<summary>Artifact details:</summary>
<br>

Image: ${CONTAINER_REPO}:${APP_VERSION}
</details>
END
)
  set_var "REPO_SUMMARY" "$SUMMARY"
}


APP_CONFIG_FILE="${GITHUB_WORKSPACE}/infra/app.conf"
if [[ -f "${APP_CONFIG_FILE}" ]]; then
    echo "Application Config detected! Loading parameters..."
    # shellcheck source=${GITHUB_WORKSPACE}/infra/app.conf
    source "${APP_CONFIG_FILE}"
else
    echo "Application Config not found here: ${APP_CONFIG_FILE}"
fi

APP_REPO="${GITHUB_REPOSITORY}"

# Resolve repository name and organization name from env variable
set_var "APP_REPO_ORG" "$(echo "${APP_REPO}" | cut -d '/' -f1)"
set_var "APP_REPO_NAME" "$(echo "${APP_REPO}"| cut -d '/' -f2)"



# Resolve App version based on branch and tags parameters
resolve_app_version

# Run report
report

generate_repo_summary
