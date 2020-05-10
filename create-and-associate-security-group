#!/usr/bin/env bash

. infra/.config

create_stack() {
    aws cloudformation create-stack \
    --stack-name ${SECURITY_GROUP_STACK} \
    --template-body file://infra/test/security-group.yml \
    --capabilities CAPABILITY_IAM \
    --region ${REGION} \
    --profile ${TEST_PROFILE}
}

CREATE_STACK_OUTPUT="$(create_stack)" || { echo "${CREATE_STACK_OUTPUT}"; exit 1; }

echo -e "Successfully triggered stack creation for ${SECURITY_GROUP_STACK}\n"

echo -e "Waiting for stack creation to finish…\n"

wait_for_stack_creation() {
    aws cloudformation --profile ${TEST_PROFILE} wait stack-create-complete --stack-name ${SECURITY_GROUP_STACK}
}

WAIT_FOR_STACK_CREATION_OUTPUT="$(wait_for_stack_creation)" || { echo "${WAIT_FOR_STACK_CREATION_OUTPUT}"; exit 1; }

echo -e "Successfully created stack ${SECURITY_GROUP_STACK}!\n"

ELASTIC_BEANSTALK_STACK_RESOURCES=$(aws --profile ${TEST_PROFILE} cloudformation describe-stack-resources --stack-name ${ELASTIC_BEANSTALK_STACK} | jq -c .StackResources[])

for resource in ${ELASTIC_BEANSTALK_STACK_RESOURCES}; do
    logical_resource_id=$(echo ${resource} | jq .LogicalResourceId | tr -d '"')
    physical_resource_id=$(echo ${resource} | jq .PhysicalResourceId | tr -d '"')
    if [[ "${logical_resource_id}" == "environment" ]]; then
        ENVIRONMENT=${physical_resource_id}
        break
    fi
done

LOAD_BALANCER=$(aws elasticbeanstalk describe-environment-resources --environment-name ${ENVIRONMENT} | jq .EnvironmentResources.LoadBalancers[0].Name | tr -d '"')

SECURITY_GROUP_STACK_RESOURCES=$(aws --profile ${TEST_PROFILE} cloudformation describe-stack-resources --stack-name ${SECURITY_GROUP_STACK} | jq -c .StackResources[])

for resource in ${SECURITY_GROUP_STACK_RESOURCES}; do
    logical_resource_id=$(echo ${resource} | jq .LogicalResourceId | tr -d '"')
    physical_resource_id=$(echo ${resource} | jq .PhysicalResourceId | tr -d '"')
    if [[ "${logical_resource_id}" == "loadBalancerSecurityGroup" ]]; then
        LOAD_BALANCER_SECURITY_GROUP=${physical_resource_id}
        break
    fi
done

echo -e "Applying new security group ${LOAD_BALANCER_SECURITY_GROUP} to load balancer for Elastic Beanstalk environment, ${LOAD_BALANCER}\n"

APPLY_SG_TO_LB_OUTPUT="$(aws elb apply-security-groups-to-load-balancer --load-balancer-name ${LOAD_BALANCER} --security-groups ${LOAD_BALANCER_SECURITY_GROUP})" || { echo "${APPLY_SG_TO_LB_OUTPUT}"; exit 1; }

SECURITY_GROUPS=$(aws --profile ${TEST_PROFILE} ec2 describe-security-groups | jq -c .SecurityGroups[])

IFS=$'\n'
for security_group in ${SECURITY_GROUPS}; do
    description=$(echo "${security_group}" | jq .Description | tr -d '"')
    group_id=$(echo "${security_group}" | jq .GroupId | tr -d '"')
    if [[ "${description}" == "SecurityGroup for ElasticBeanstalk environment." ]]; then
        AUTO_GENERATED_ELASTIC_BEANSTALK_SECURITY_GROUP=${group_id}
        break
    fi
done
unset IFS

echo -e "Associating new security group ${LOAD_BALANCER_SECURITY_GROUP} with the auto-generated security group for EC2 Elastic Beanstalk instance(s). This will grant anyone on the web access to the Elastic Beanstalk app.\n"

ASSOCIATE_LB_SG_WITH_EB_SG_OUTPUT="$(aws --profile ${TEST_PROFILE} ec2 authorize-security-group-ingress --group-id ${AUTO_GENERATED_ELASTIC_BEANSTALK_SECURITY_GROUP} --source-group ${LOAD_BALANCER_SECURITY_GROUP} --protocol tcp --port 80)" || { echo "${ASSOCIATE_LB_SG_WITH_EB_SG_OUTPUT}"; exit 1; }

echo "Done!"
