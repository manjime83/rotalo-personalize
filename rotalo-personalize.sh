#!/bin/bash

aws cloudformation deploy \
    --template-file rotalo-personalize.yaml \
    --stack-name rotalo-dev-personalize \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides ProjectName=rotalo EnvironmentType=dev