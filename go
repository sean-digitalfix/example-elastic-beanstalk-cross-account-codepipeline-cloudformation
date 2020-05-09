#!/usr/bin/env bash

./infra/tools/create-pre-reqs-stack.sh

./infra/test/create-elastic-beanstalk-stack.sh

./infra/test/create-iam-stack.sh

./infra/tools/create-pipeline-stack.sh

./infra/tools/update-pre-reqs-stack.sh
