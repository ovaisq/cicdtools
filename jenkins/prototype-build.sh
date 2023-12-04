#!/bin/bash
echo "cat ~/.bash_profile"
cat ~/.bash_profile

. ~/.bash_profile

wrkspc=$(pwd)
export TEST_PATH=tests/jira-ui
ENV_SETUP=tests/scripts/jenkins/env_setup.sh
FN_SETUP=tests/scripts/jenkins/setup_functions.sh

if [ -e "${FN_SETUP}" ]; then
  echo "Found setup script in branch"
  source "${FN_SETUP}"
else
  echo "Why isn't the function script in the branch?"
  function announce_host() { ip -o -4 -f inet addr | grep eth | sed -e 's/^.*inet //' -e 's/\/16.*$//'; }
  function lower() { tr '[:upper:]' '[:lower:]'; }
  function env_file() { echo ".env.${TARGET}" | lower; }
  function grab_env() { cat $(env_file) | sed -e "s/^${TARGET}_//" | grep "^$1=" | sed -e 's/^.*=//'; }
fi

if [ -e "${ENV_SETUP}" ]; then
  echo "Found setup script in branch"
  source "${ENV_SETUP}"
else
  echo "Why isn't the setup script in the branch?"
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

fi

echo " "
echo "Starting test on host: $(announce_host)"
echo " "
echo "PLATFORM                       = ${PLATFORM}"
echo "TEST_BROWSER                   = ${TEST_BROWSER}"
echo "TARGET                         = ${TARGET}"
echo "URL                            = ${URL}"
echo "JIRA_API_PROJECT               = ${URL}${JIRA_API_PROJECT}"
echo "JIRA_API_ISSUE                 = ${URL}${JIRA_API_ISSUE}"
echo "LOGIN_URL                      = ${LOGIN_URL}"
echo "LANDING_URL                    = ${LANDING_URL}"
echo "SERVER_VERSION                 = ${SERVER_VERSION}"
echo "BRANCH_NAME                    = ${BRANCH_NAME}"
echo "TEST_PLATFORM                  = ${TEST_PLATFORM}"
echo "SAUCE_USERNAME                 = ${SAUCE_USERNAME}"
echo "SAUCE_ACCESSKEY                = ${SAUCE_ACCESSKEY}"
echo "SELENIUM_SERVER_URL            = ${SELENIUM_SERVER_URL}"
echo "GCC_PERF_DIAGRAM_FILE          = ${GCC_PERF_DIAGRAM_FILE}"
echo "JIRA_IMPORT_DIAGRAM_PATH       = ${JIRA_IMPORT_DIAGRAM_PATH}"
echo "CUCUMBER_CMD                   = ${CUCUMBER_CMD}"
echo "TAGS                           = ${TAGS}"
echo "DEBUG                          = ${DEBUG}"
echo " "

export PATH=/usr/local/bin:$PATH
#lynx --dump http://${TARGET}.domain.com/go/svrStatus | grep -v Memory | grep -v pct | grep -v Pool. | grep -v Threading
echo "Current PATH: ${PATH}"

echo "cd ${TEST_PATH}"
cd "${TEST_PATH}"
echo "current working directory: $(pwd)"

echo "npm config set cache \"${wrkspc}/../.npm\""
npm config set cache "${wrkspc}/../.npm"
echo "npm config get cache"
npm config ls get cache
echo "npm --silent -g i npm >> /dev/null"
npm --silent -g i npm >> /dev/null
echo "npm --silent install >> /dev/null"
npm --silent install >> /dev/null
echo "nvm install stable"
nvm install stable
echo "npm --versions"
npm --versions

echo "pwd"
pwd

echo "find . -type f -name 'cucumber.js'"
find . -type f -name 'cucumber.js'

# what account is running here?
id

# what is the default cucumber.js we'll run
which cucumber.js

# Checking to see if the target exists
ls -l .env.$(echo ${TARGET} | tr '[:upper:]' '[:lower:]')

# # Fix npm run test -- npm eats the command arguments poorly
# export CUCUMBER_CMD=${CUCUMBER_CMD/npm\ run\ test\ --/./node_modules/cucumber/bin/cucumber.js}
#
# Convert the TAGS environment variable to the --tags arguments
let i=0
tags="--tags '"
for tag in ${TAGS//,/ }; do
  [ $i -gt 0 ] && tags="${tags} or "
  tags="${tags}${tag}"
  ((i++))
done
tags="${tags}'"

# Turn off color output for jenkins
FORMAT_OPTIONS=" --format-options '{\"colorsEnabled\": false}'"
function eval_command () {
  echo "***** $@ *****";
  let i=0;
  for a in "$@"; do
    echo "argv[$i] = $a";
    ((i++));
  done;
  cmd="$@"
  eval $cmd;
}
eval_command "${CUCUMBER_CMD} ${tags} ${FORMAT_OPTIONS}"
# eval_command ${CUCUMBER_CMD} ${tags}

test_status="$?"


#FILESIZE=$(wc -c "@rerun.txt")
#echo "Size of @rerun.txt = $FILESIZE bytes."
#if [ -s "@rerun.txt" ]; then
 #   cat @rerun.txt
    #npm run test @rerun.txt
  #  cucumber.js @rerun.txt
   # test_status="$?"
#fi

# Install a junit report module for cucumber
npm install cucumberjs-junitxml --save-dev
# Convert the cucumber report to junit
cat results.json | ./node_modules/.bin/cucumber-junit > results.xml

# Let's at leaset make result file name contain env under test info
mv results.json results_${BUILD_NUMBER}_${TARGET}_${SERVER_VERSION}_${TEST_BROWSER}_${GIT_REVISION:0:8}.json
mv results.xml results_${BUILD_NUMBER}_${TARGET}_${SERVER_VERSION}_${TEST_BROWSER}_${GIT_REVISION:0:8}.xml

#for j in results*.json; do
#  cat ${j} | ./node_modules/.bin/cucumber-junit > "${j%.xml%.json}"
#done

# Recreate the test status from the npm test command
[ "${test_status}" == "0" ] && true || false
