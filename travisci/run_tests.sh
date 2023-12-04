#!/usr/bin/env bash
# ATL_API_TOKEN_EMAIL, ATL_API_TOKEN, and CICD_GITHUB_TOKEN are defined here:
#  http://qa-jenkins-prod.company.roguewave.com:8080/configure

GITHUB_API_URL="https://api.github.com"
GITHUB_API_ROUTE="/repos/"

#company app
COMPANY_GCC_URL="https://confluence-connect.$ENVIRONMENT.nonprod-company.net/atlassian-connect.json"
ATL_PLUGIN_KEY_PATH="/rest/plugins/1.0/com.company.integration.confluence-key"

echo "Starting Smoke Tests on $ENVIRONMENT"

test_instance_type=$(basename "${URL}")

if [[ "$test_instance_type" != "wiki" ]]
then
	echo "ERROR: ${URL} is not a valid Confluence Cloud URL"
	exit -1
fi

#github PR status update
curl -sqX POST -H "Authorization: token ${CICD_GITHUB_TOKEN}" \
-H 'Content-Type: application/json' \
--data '{"state": "pending","context":"CICD: Smoke Tests","description":" In Progress","target_url": "'${BUILD_URL}'"}' \
"${GITHUB_API_URL}""${GITHUB_API_ROUTE}""${TRAVIS_PULL_REQUEST_SLUG}"/statuses/"${TRAVIS_PULL_REQUEST_SHA}" \
-o /dev/null

echo "cat ~/.bash_profile"
cat ~/.bash_profile

. ~/.bash_profile
export PATH=/usr/local/bin:/sbin:$PATH

function announce_host() { ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'; }

echo -e "Current PATH:\n${PATH}"

echo "cd tests/confluence-ui"
cd tests/confluence-ui
echo "current working directory: $(pwd)"

echo "The PATH is:"
echo $PATH | tr ':' '\n' | sed -e 's/^/    /'

echo "npm --silent -g i npm >> /dev/null"
npm --silent -g i npm >> /dev/null
echo "npm i -S yarn"
npm i -S yarn

echo "find . -name 'yarn' -type f"
find . -name 'yarn' -type f

echo "yarn=\"$(find . -name 'yarn' -type f)\""
yarn="$(find . -name 'yarn' -type f)"

echo "yarn --version"
$yarn --version

echo "yarn install"
$yarn install >> /dev/null

echo "uname -a"
uname -a

echo "current working directory: $(pwd)"

echo "find . -type d -name @test -prune -o -type f -perm /111 -name 'cucumber.js' -print"
find . -type d -name @test -prune -o -type f -perm /111 -name 'cucumber.js' -print

cuke="$(find . -type d -name @test -prune -o -type f -perm /111 -name 'cucumber.js' -print)"
cfmt="--format-options {\\\"colorsEnabled\\\":false}"

#cicd NEW_TESTS is a GLOBAL defined in .travis.yml
#  passed through to test runner Jenkins job, starting at first though with
#  the Deployment script
if [[ "$NEW_TESTS" =~ ^"@" ]]
then
	TAG_EXPRESSION="$TAG_EXPRESSION and $NEW_TESTS"
	tags="-t \"${TAG_EXPRESSION:-@cloud}\""
else
	tags="-t \"${TAG_EXPRESSION:-@cloud}\""
fi

#atlassian api
CONF_CLOUD_VERSION="$(curl -qs "${URL}"/rest/api/settings/systemInfo --user "$ATL_API_TOKEN_EMAIL":"$ATL_API_TOKEN" --header "Accept: application/json" | jq -r '.commitHash')"
ATL_PLUGIN_INFO=$(curl -sq "${URL}"/rest/plugins/1.0/installed-marketplace?updates=true --user $ATL_API_TOKEN_EMAIL:$ATL_API_TOKEN --header 'Accept: application/json,text/javascript, */*; q=0.01' | jq -r '.plugins[].links[]' 2>&1)

if [[ "$ATL_PLUGIN_INFO" =~ ^"jq: error" ]]
then 
	echo "Error: unable to access plugin information"
	exit -1
else
	COMPANY_PLUGIN_VER="$(basename $(echo "$ATL_PLUGIN_INFO" |grep com.company.integration.confluence | grep pac-details))"
fi

if [ -z "$COMPANY_PLUGIN_VER" ]
then
	COMPANY_PLUGIN_VER="Not_Installed"
else
	echo "Removing Company Plugin version $COMPANY_PLUGIN_VER"
    #un-register installed plugin before it can be removed
    echo "Un-Register"
	curl --user "${ATL_API_TOKEN_EMAIL}":"${ATL_API_TOKEN}" -sq -XPOST "${URL}"/rest/plugins/1.0/license-tokens \
    -H 'Accept: */*' \
    -H 'Content-Type: application/vnd.atl.plugins+json' \
    -d '{"pluginKey": "com.company.integration.confluence","token": "","state": "NONE"}'\
	-o /dev/null
    sleep 2s
    #remove the plugin
    echo "Delete Plugin"
    curl --user "${ATL_API_TOKEN_EMAIL}":"${ATL_API_TOKEN}" \
	-H 'Accept: application/json' \
	-H 'Content-Type: application/json' \
	-sq -XDELETE "${URL}""${ATL_PLUGIN_KEY_PATH}" \
	-o /dev/null
	sleep 5s 
fi

#company connector metadata - Company side
COMPANY_METADATA="$(curl -sq https://confluence-connect."${ENVIRONMENT}".nonprod-company.net/metadata.json | jq .)"
#get upm-token. needed for installing plugin
echo "UPM Token"
UPM_TOKEN=$(curl --user "${ATL_API_TOKEN_EMAIL}":"${ATL_API_TOKEN}" -sqI -H "Accept: application/vnd.atl.plugins.installed+json" -XGET ""${URL}"/rest/plugins/1.0/?os_authType=basic" | grep upm-token | cut -d: -f2- | tr -d '[[:space:]]')

#install plugin
echo "Installing"
curl --user "${ATL_API_TOKEN_EMAIL}":"${ATL_API_TOKEN}" -sq -XPOST "${URL}"/rest/plugins/1.0/?token="${UPM_TOKEN}" \
-H 'Accept: application/json' \
-H 'Content-Type: application/vnd.atl.plugins.remote.install+json' \
-d '{"pluginUri": "https://confluence-connect.'${ENVIRONMENT}'.nonprod-company.net","pluginName": "Company Diagrams for Confluence Cloud"}' \
-o /dev/null
echo " "

status_code=$(curl --user "${ATL_API_TOKEN_EMAIL}":"${ATL_API_TOKEN}" -sI -XGET ""${URL}""${ATL_PLUGIN_KEY_PATH}""| head -n1| cut -d$' ' -f2)
# loop till it's deployed, but time out at 240 seconds
TIME_SECONDS=$(date +'%s')
START_TIME=$TIME_SECONDS
END_TIME=$(date +'%s')
SLEEP_TIMEOUT=1000
while [[ $status_code -ne 200 ]]
do
	if [[ $(($(date +'%s') - $TIME_SECONDS)) -ge $SLEEP_TIMEOUT ]]
	then
		echo "Took longer than $SLEEP_TIMEOUT to update. Try again!"
		exit -1
	else
		# ATL_API_* vars declared here http://qa-jenkins-prod.company.roguewave.com:8080/configure
		status_code=$(curl --user "${ATL_API_TOKEN_EMAIL}":"${ATL_API_TOKEN}" -sI -XGET ""${URL}""${ATL_PLUGIN_KEY_PATH}""| head -n1| cut -d$' ' -f2)
		echo "Installation in progress"
		# Atlassian Cloud instance freaks out - 409s - if polled too frequent
		#  so uping the sleep to 5s from 2s
		sleep 5s
	fi
done
echo "Installation completed"

#atlassian api
COMPANY_PLUGIN_VER="$(basename $(curl -sq "${URL}"/rest/plugins/1.0/installed-marketplace?updates=true --user $ATL_API_TOKEN_EMAIL:$ATL_API_TOKEN --header 'Accept: application/json,text/javascript, */*; q=0.01' | jq -r '.plugins[].links[]' |grep com.company.integration.confluence | grep pac-details))"
ENV_FILE="ENV_FILE_${BUILD_NUMBER}.property"
rm -f ${ENV_FILE}
echo "COMPANY_PLUGIN_VER = $COMPANY_PLUGIN_VER" > ${ENV_FILE}

#register installed plugin before it can be used to create diagrams
# ATL_PRIVATE_LISTING_TOKEN_GCC_2 is defined here http://qa-jenkins-prod.company.roguewave.com:8080/configure
echo "Register"
curl --user "${ATL_API_TOKEN_EMAIL}":"${ATL_API_TOKEN}" -sq -XPOST "${URL}"/rest/plugins/1.0/license-tokens \
-H 'Accept: */*' \
-H 'Content-Type: application/vnd.atl.plugins+json' \
-d '{"pluginKey": "com.company.integration.confluence","token": "'${ATL_PRIVATE_LISTING_TOKEN_GCC_2}'","state": "ACTIVE_SUBSCRIPTION"}' \
-o /dev/null
sleep 2s

echo " "
echo "Starting test on host: $(announce_host)"
echo " "
echo "PLATFORM                       = ${PLATFORM}"
echo "TEST_BROWSER                   = ${TEST_BROWSER}"
echo "TARGET                         = ${TARGET}"
echo "URL                            = ${URL}"
echo "CONFLUENCE CLOUD VERSION       = ${CONF_CLOUD_VERSION}"
echo "COMPANY PLUGIN VERSION          = ${COMPANY_PLUGIN_VER}"
echo "BRANCH_NAME                    = ${BRANCH_NAME}"
echo "TEST_PLATFORM                  = ${TEST_PLATFORM}"
echo "SAUCE_USERNAME                 = ${SAUCE_USERNAME}"
echo "SAUCE_ACCESSKEY                = ${SAUCE_ACCESSKEY}"
echo "SELENIUM_SERVER_URL            = ${SELENIUM_SERVER_URL}"
echo "CONFLUENCE_DIAGRAM_PATH        = ${CONFLUENCE_DIAGRAM_PATH}"
echo "Computed command               = ${cuke} ${tags} ${cfmt}"
echo "DEBUG                          = ${DEBUG}"
echo "USERNAME                       = ${USERNAME}"
echo "PASSWORD                       = ${PASSWORD}"
echo "LOCA_USERNAME                  = ${LOCA_USERNAME}"
echo "PASSWORD                       = ${LOCA_PASSWORD}"
echo "CONFLUENCE_PLUGIN_KEY          = ${CONFLUENCE_PLUGIN_KEY}"
echo "COMPANY_METADATA                = ${COMPANY_METADATA}"
echo "ENVIRONMENT                    = ${ENVIRONMENT}"
echo "TRAVIS_PULL_REQUEST            = ${TRAVIS_PULL_REQUEST}"
echo "TRAVIS_PULL_REQUEST_SHA        = ${TRAVIS_PULL_REQUEST_SHA}"
echo "TRAVIS_PULL_REQUEST_SLUG       = ${TRAVIS_PULL_REQUEST_SLUG}"

echo " "

# what account is running here?
id

eval ${cuke} ${tags} ${cfmt}
test_status="$?"

if [[ $test_status -ne 0 ]]
then
	#github PR status update
	curl -sqX POST -H "Authorization: token ${CICD_GITHUB_TOKEN}" \
	-H 'Content-Type: application/json' \
	--data '{"state": "failure","context":"CICD: Smoke Tests","description":" Tests Failed","target_url":"'${BUILD_URL}'"}' \
	"${GITHUB_API_URL}""${GITHUB_API_ROUTE}""${TRAVIS_PULL_REQUEST_SLUG}"/statuses/"${TRAVIS_PULL_REQUEST_SHA}" \
	-o /dev/null
else
	#github PR status update
	curl -sqX POST -H "Authorization: token ${CICD_GITHUB_TOKEN}" \
	-H 'Content-Type: application/json' \
	--data '{"state": "success","context":"CICD: Smoke Tests","description":" Tests Passed","target_url": "'${BUILD_URL}'"}' \
	"${GITHUB_API_URL}""${GITHUB_API_ROUTE}""${TRAVIS_PULL_REQUEST_SLUG}"/statuses/"${TRAVIS_PULL_REQUEST_SHA}" \
	-o /dev/null
fi

# Install a junit report module for cucumber
npm install cucumberjs-junitxml --save-dev
# Convert the cucumber report to junit
cat results.json | ./node_modules/.bin/cucumber-junit > results.xml

# Let's at leaset make result file name contain env under test info
mv results.json results_${BUILD_NUMBER}_${TARGET}_${SERVER_VERSION}_${TEST_BROWSER}_${GIT_REVISION:0:8}.json
mv results.xml results_${BUILD_NUMBER}_${TARGET}_${SERVER_VERSION}_${TEST_BROWSER}_${GIT_REVISION:0:8}.xml

# Recreate the test status from the npm test command
[ "${test_status}" == "0" ] && true || false
