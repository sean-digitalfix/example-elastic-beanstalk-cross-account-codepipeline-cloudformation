#!/usr/bin/env bash

. "$(dirname "$0")"/../.config

create_stack() {
    aws cloudformation create-stack \
    --stack-name ${PRE_REQS_STACK} \
    --template-body file://${PRE_REQS_TEMPLATE} \
    --parameters \
    ParameterKey=testAccount,ParameterValue=${TEST_ACCOUNT} \
    ParameterKey=project,ParameterValue=${PROJECT_NAME} \
    --capabilities CAPABILITY_IAM \
    --region ${REGION} \
    --profile ${TOOLS_PROFILE}
}

CREATE_STACK_OUTPUT="$(create_stack)" || { echo "${CREATE_STACK_OUTPUT}"; exit 1; }

echo -e "Successfully triggered stack creation for ${PRE_REQS_STACK}\n"

echo -e "Waiting for stack creation to finish…\n"

wait_for_stack_creation() {
    aws cloudformation --profile ${TOOLS_PROFILE} wait stack-create-complete --stack-name ${PRE_REQS_STACK}
}

WAIT_FOR_STACK_CREATION_OUTPUT="$(wait_for_stack_creation)" || { echo "${WAIT_FOR_STACK_CREATION_OUTPUT}"; exit 1; }

echo -e "Successfully created stack ${PRE_REQS_STACK}!\n"

STACK_RESOURCES=$(aws --profile ${TOOLS_PROFILE} cloudformation describe-stack-resources --stack-name ${PRE_REQS_STACK} | jq -c .StackResources[])

for resource in ${STACK_RESOURCES}; do
    logical_resource_id=$(echo ${resource} | jq .LogicalResourceId | tr -d '"')
    physical_resource_id=$(echo ${resource} | jq .PhysicalResourceId | tr -d '"')
    if [[ "${logical_resource_id}" == "artifactBucket" ]]; then
        ARTIFACT_BUCKET=${physical_resource_id}
    elif [[ "${logical_resource_id}" == "kmsKey" ]]; then
        CMK=${physical_resource_id}
    fi
done

ACCOUNT_ID=$(aws --profile ${TOOLS_PROFILE} sts get-caller-identity --query Account --output text)

echo -e "Writing newly-created KMS key and S3 artifact bucket to infra/test/iam.json\n"

echo '[
  {
    "ParameterKey": "toolsAccount",
    "ParameterValue": "101256382798"
  },
  {
    "ParameterKey": "cmk",
    "ParameterValue": "arn:aws:kms:'"$REGION"':'"$ACCOUNT_ID"':key/'"$CMK"'"
  },
  {
    "ParameterKey": "artifactBucket",
    "ParameterValue": "arn:aws:s3:::'"$ARTIFACT_BUCKET"'"
  }
]' > infra/test/iam.json

echo -e "DONE!\n"
