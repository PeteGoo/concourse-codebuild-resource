#!/bin/bash

BUILD_ID=$1

echo "fetching log group for $BUILD_ID"
LOG_GROUP=`aws codebuild batch-get-builds --ids $BUILD_ID --query 'builds[*].logs.groupName' --output text`
LOG_STREAM=`aws codebuild batch-get-builds --ids $BUILD_ID --query 'builds[*].logs.streamName' --output text`
echo "log group for $BUILD_ID is $LOG_GROUP,  Stream: $LOG_STREAM"

awslogs get $LOG_GROUP $LOG_STREAM --watch | sed '/Phase complete: POST_BUILD/ q'