#!/bin/bash
# ******IMPORTANT*****: this script relies on "ecs" tool located here:
#                       https://pypi.org/project/ecs-deploy/
#						"pip install ecs-deploy"
#                       and awscli
#                       "pip install awscli"
# ${CICD_GITHUB_TOKEN} is a Jenkins Global Variable
#
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
export AWS_DEFAULT_REGION=us-east-1

#cicd
EXPECTED_VERSION="$(echo $IMAGE_TAG | sed -e 's/.*://g')"
GITHUB_API_URL="https://api.github.com"
GITHUB_API_ROUTE="/repos/"

#company app
COMPANY_GCC_URL="https://confluence-connect.$ENVIRONMENT.nonprod-company.net/atlassian-connect.json"

#github status update
echo "Deploying $APP_NAME on $ENVIRONMENT"
curl -sqX POST -H "Authorization: token ${CICD_GITHUB_TOKEN}" \
-H 'Content-Type: application/json' \
--data '{"state": "pending","context":"CICD: Image Deploy","description":" In Progress","target_url": "'${BUILD_URL}'"}' \
"${GITHUB_API_URL}""${GITHUB_API_ROUTE}""${TRAVIS_PULL_REQUEST_SLUG}"/statuses/"${TRAVIS_PULL_REQUEST_SHA}" \
-o /dev/null

if [[ "$IMAGE_TAG" =~ ^company\/.*:.* ]]
then

    if [ "${USER:-unassigned}" == "unassigned" ]
	then
       	echo "You must assign your user name using first.last or <first-initial>.<last>"
       	exit 1
    fi

    if [ "$APP_NAME" = "gjc" ]
	then 
		SVC_NAME="$APP_NAME-public"
		echo $SVC_NAME
		ecs deploy $ENVIRONMENT $SVC_NAME --image $APP_NAME $IMAGE_TAG --timeout -1
		SVC_NAME="$APP_NAME-private"
		ecs deploy $ENVIRONMENT $SVC_NAME --image $APP_NAME $IMAGE_TAG --timeout -1
		APP_NAME="$APP_NAME-public"
		echo $APP_NAME
    else
		echo "Deploying $APP_NAME $IMAGE_TAG"
       	ecs deploy $ENVIRONMENT $APP_NAME --image $APP_NAME $IMAGE_TAG --timeout -1
    fi

	# loop till it's deployed, but time out at 240 seconds
	TIME_SECONDS=$(date +'%s')
	START_TIME=$TIME_SECONDS
	END_TIME=$(date +'%s')
	SLEEP_TIMEOUT=1000
	COMPANY_CONNECTOR_VERSION=$(curl -sq -X GET $COMPANY_GCC_URL | jq -r '.version')
	while [[ ! "$EXPECTED_VERSION" == "$COMPANY_CONNECTOR_VERSION" ]]
	do
		COMPANY_CONNECTOR_VERSION=$(curl -sq -X GET $COMPANY_GCC_URL | jq -r '.version')
		echo "Connector Version: $COMPANY_CONNECTOR_VERSION"
		echo "Expected Version: $EXPECTED_VERSION"
		if [[ $(($(date +'%s') - $TIME_SECONDS)) -ge $SLEEP_TIMEOUT ]]
		then
			echo "Connector Version: $COMPANY_CONNECTOR_VERSION"
			echo "Took longer than $SLEEP_TIMEOUT to update. Try again!"
			#github status update
			curl -sqX POST -H "Authorization: token ${CICD_GITHUB_TOKEN}" \
			-H 'Content-Type: application/json' \
			--data '{"state": "error","context":"CICD: Image Deploy","description":" Error: Timeout","target_url": "'${BUILD_URL}'"}' \
			"${GITHUB_API_URL}""${GITHUB_API_ROUTE}""${TRAVIS_PULL_REQUEST_SLUG}"/statuses/"${TRAVIS_PULL_REQUEST_SHA}" \
			-o /dev/null
			exit -1
		 else
			echo "Waiting for image to finish deploying... $(($(date +'%s') - $TIME_SECONDS))"
			echo "Connector Version: $COMPANY_CONNECTOR_VERSION"
			sleep 5s
		fi
	done
	#github status update
	curl -sqX POST -H "Authorization: token ${CICD_GITHUB_TOKEN}" \
	-H 'Content-Type: application/json' \
	--data '{"state": "success","context":"CICD: Image Deploy","description":" Successful","target_url": "'${BUILD_URL}'"}' \
	"${GITHUB_API_URL}""${GITHUB_API_ROUTE}""${TRAVIS_PULL_REQUEST_SLUG}"/statuses/"${TRAVIS_PULL_REQUEST_SHA}" \
	-o /dev/null
	echo "$IMAGE_TAG deployed successfully!"

else
    echo "$IMAGE_TAG is invalid"
	#github status update
	curl -sqX POST -H "Authorization: token ${CICD_GITHUB_TOKEN}" \
	-H 'Content-Type: application/json' \
	--data '{"state": "error","context":"CICD: Image Deploy","description":" Error: Invalid Image Tag","target_url": "'${BUILD_URL}'"}' \
	"${GITHUB_API_URL}""${GITHUB_API_ROUTE}""${TRAVIS_PULL_REQUEST_SLUG}"/statuses/"${TRAVIS_PULL_REQUEST_SHA}" \
	-o /dev/null
    exit -1
fi

TASK_DEF=`aws ecs describe-services --cluster "${ENVIRONMENT}" --services "${APP_NAME}" | jq -r '.services[0].deployments[0].taskDefinition'`
echo ${TASK_DEF}
ECS_IMAGE=`aws ecs describe-task-definition --task-definition ${TASK_DEF} | jq -r '.taskDefinition.containerDefinitions[0].image'`
echo ${ECS_IMAGE}

if [ "$IMAGE_TAG" = "$ECS_IMAGE" ]
then
	echo deployment successful && exit 0
else
	echo deployment failed && exit -1
fi
