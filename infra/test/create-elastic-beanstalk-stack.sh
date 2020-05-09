#!/usr/bin/env bash

. "$(dirname "$0")"/../.config

create_stack() {
    aws cloudformation create-stack \
    --stack-name ${ELASTIC_BEANSTALK_STACK} \
    --template-body file://${ELASTIC_BEANSTALK_TEMPLATE} \
    --capabilities CAPABILITY_IAM \
    --region ${REGION} \
    --profile ${TEST_PROFILE}
}

CREATE_STACK_OUTPUT="$(create_stack)" || { echo "${CREATE_STACK_OUTPUT}"; exit 1; }

echo -e "Successfully triggered stack creation for ${ELASTIC_BEANSTALK_STACK}\n"

echo -e "Waiting for stack creation to finish…\n"

wait_for_stack_creation() {
    aws cloudformation --profile ${TEST_PROFILE} wait stack-create-complete --stack-name ${ELASTIC_BEANSTALK_STACK}
}

WAIT_FOR_STACK_CREATION_OUTPUT="$(wait_for_stack_creation)" || { echo "${WAIT_FOR_STACK_CREATION_OUTPUT}"; exit 1; }

echo -e "Successfully created stack ${ELASTIC_BEANSTALK_STACK}!\n"

STACK_RESOURCES=$(aws --profile ${TEST_PROFILE} cloudformation describe-stack-resources --stack-name ${ELASTIC_BEANSTALK_STACK} | jq -c .StackResources[])

for resource in ${STACK_RESOURCES}; do
    logical_resource_id=$(echo ${resource} | jq .LogicalResourceId | tr -d '"')
    physical_resource_id=$(echo ${resource} | jq .PhysicalResourceId | tr -d '"')
    if [[ "${logical_resource_id}" == "app" ]]; then
        APP=${physical_resource_id}
    elif [[ "${logical_resource_id}" == "environment" ]]; then
        ENVIRONMENT=${physical_resource_id}
    fi
done

echo -e "Writing parameters for continuous integration pipeline to infra/tools/pipeline.json\n"

echo '[
  {
    "ParameterKey": "testAccount",
    "ParameterValue": "'"$TEST_ACCOUNT"'"
  },
  {
    "ParameterKey": "project",
    "ParameterValue": "'"$PROJECT_NAME"'"
  },
  {
    "ParameterKey": "gitHubRepositoryOwner",
    "ParameterValue": "'"$GITHUB_USERNAME"'"
  },
  {
    "ParameterKey": "gitHubRepository",
    "ParameterValue": "'"$GITHUB_REPO"'"
  },
  {
    "ParameterKey": "elasticBeanstalkTemplate",
    "ParameterValue": "elastic-beanstalk.yml"
  },
  {
    "ParameterKey": "app",
    "ParameterValue": "'"$APP"'"
  },
  {
    "ParameterKey": "environment",
    "ParameterValue": "'"$ENVIRONMENT"'"
  },
  {
    "ParameterKey": "elasticBeanstalkStack",
    "ParameterValue": "'"$ELASTIC_BEANSTALK_STACK"'"
  }
]' > infra/tools/pipeline.json

echo -e "DONE!\n"
