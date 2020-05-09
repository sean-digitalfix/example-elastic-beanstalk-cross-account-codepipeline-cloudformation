#!/usr/bin/env bash

. "$(dirname "$0")"/../.config

echo -e "Updating ${PRE_REQS_STACK} in tools account to add CodeBuild and CodePipeline roles as KMS CMK Principal\n"

deploy_changes() {
    aws cloudformation deploy \
        --stack-name ${PRE_REQS_STACK} \
        --template-file ${PRE_REQS_TEMPLATE} \
        --parameter-overrides codeBuildCondition=true \
        --capabilities CAPABILITY_IAM \
        --region ${REGION} \
        --profile ${TOOLS_PROFILE}
}

DEPLOY_CHANGES_OUTPUT="$(deploy_changes)" || { echo "${DEPLOY_CHANGES_OUTPUT}"; exit 1; }

echo -e "Waiting for stack update to finish…\n"

wait_for_stack_update() {
    aws cloudformation --profile ${TOOLS_PROFILE} wait stack-update-complete --stack-name ${PRE_REQS_STACK}
}

WAIT_FOR_STACK_UPDATE_OUTPUT="$(wait_for_stack_update)" || { echo "${WAIT_FOR_STACK_UPDATE_OUTPUT}"; exit 1; }

echo "DONE!"
