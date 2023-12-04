#!/bin/bash
  cd "${TEST_PATH}"
  echo "cat $(env_file)"
  cat $(env_file)
  echo "Before grabbing variables:"
  echo "URL              = ${URL:-Empty or non-existent}"
  echo "LOGIN_URL        = ${LOGIN_URL:-Empty or non-existent}"
  echo "LANDING_URL      = ${LANDING_URL:-Empty or non-existent}"
  echo "JIRA_API_PROJECT = ${JIRA_API_PROJECT:-Empty or non-existent}"
  echo "JIRA_API_ISSUE   = ${JIRA_API_ISSUE:-Empty or non-existent}"
  [ "${URL:-empty}" == "empty" ] && echo "URL was empty"
  export URL="${URL:-$(grab_env URL)}"
  [ "${LOGIN_URL:-empty}" == "empty" ] && echo "LOGIN_URL was empty"
  export LOGIN_URL="${LOGIN_URL:-$(grab_env LOGIN_URL)}"
  [ "${LANDING_URL:-empty}" == "empty" ] && echo "LANDING_URL was empty"
  export LANDING_URL="${LANDING_URL:-$(grab_env LANDING_URL)}"
  [ "${JIRA_API_PROJECT:-empty}" == "empty" ] && echo "JIRA_API_PROJECT was empty"
  export JIRA_API_PROJECT="${JIRA_API_PROJECT:-$(grab_env JIRA_API_PROJECT)}"
  [ "${JIRA_API_ISSUE:-empty}" == "empty" ] && echo "JIRA_API_ISSUE was empty"
  export JIRA_API_ISSUE="${JIRA_API_ISSUE:-$(grab_env JIRA_API_ISSUE)}"
  cd -
  export MANIFEST_PATH="/rest/applinks/1.0/manifest.json"
  export MANIFEST="$(curl -sq ${URL}${MANIFEST_PATH})"
  export SERVER_VERSION=$(echo ${MANIFEST} | jq .version -r)
  export SERVER_TYPE="$(echo $MANIFEST | jq .typeId -r)_server"
  export SERVER_BUILD="bld_$(echo $MANIFEST | jq .buildNumber -r)"

  echo "After grabbing variables:"
  echo "URL              = ${URL:-Empty or non-existent}"
  echo "LOGIN_URL        = ${LOGIN_URL:-Empty or non-existent}"
  echo "LANDING_URL      = ${LANDING_URL:-Empty or non-existent}"
  echo "JIRA_API_PROJECT = ${JIRA_API_PROJECT:-Empty or non-existent}"
  echo "JIRA_API_ISSUE   = ${JIRA_API_ISSUE:-Empty or non-existent}"
