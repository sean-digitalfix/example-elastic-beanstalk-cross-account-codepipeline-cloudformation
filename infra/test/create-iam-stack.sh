#!/usr/bin/env bash

. "$(dirname "$0")"/../.config

create_stack() {
    aws cloudformation create-stack \
        --stack-name ${IAM_STACK} \
        --template-body file://${IAM_TEMPLATE} \
        --parameters file://${IAM_PARAMETERS} \
        --capabilities CAPABILITY_NAMED_IAM \
        --region ${REGION} \
        --profile ${TEST_PROFILE}
}

CREATE_STACK_OUTPUT="$(create_stack)" || { echo "${CREATE_STACK_OUTPUT}"; exit 1; }

echo -e "Successfully triggered stack creation for ${IAM_STACK}\n"

echo -e "Waiting for stack creation to finish…\n"

wait_for_stack_creation() {
    aws cloudformation --profile ${TEST_PROFILE} wait stack-create-complete --stack-name ${IAM_STACK}
}

WAIT_FOR_STACK_CREATION_OUTPUT="$(wait_for_stack_creation)" || { echo "${WAIT_FOR_STACK_CREATION_OUTPUT}"; exit 1; }

echo -e "Successfully created stack ${IAM_STACK}!\n"

echo -e "DONE!\n"
