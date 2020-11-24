export TMPDIR=${TMPDIR:-/tmp}


assume_role() {
    role=$1
    assumed_role_details=$(aws sts assume-role --role-arn "$1" --role-session-name concourse)
    access_key_id=$(echo $assumed_role_details | jq -s '.AccessKeyId')
    secret_access_key=$(echo $assumed_role_details | jq -s '.SecretAccessKey')
    session_token=$(echo $assumed_role_details | jq -s '.SessionToken')

    export AWS_ACCESS_KEY_ID=$access_key_id
    export AWS_SECRET_ACCESS_KEY=$secret_access_key
    export AWS_SESSION_TOKEN=$session_token
}

wait_for_build_to_finish() {
    WAIT_FOR_BUILD_ID=$1

    while :
    do

    BUILD_STATUS=$(aws codebuild batch-get-builds --ids $WAIT_FOR_BUILD_ID --query 'builds[*].buildStatus' --output text)

    if [ $BUILD_STATUS != 'IN_PROGRESS' ]
    then
        echo "Build finished with result $BUILD_STATUS"
        break #Abandon the loop.
    fi

    sleep 10
    done
}

wait_for_log_stream() {
    WAIT_FOR_BUILD_ID=$1
    NOT_ACCEPTABLE_PHASES=("SUBMITTED" "QUEUED" "PROVISIONING" "DOWNLOAD_SOURCE")

    echo "Waiting for the build $WAIT_FOR_BUILD_ID to enter a suitable phase for streaming the logs."

    while :
    do

    BUILD_STATUS=$(aws codebuild batch-get-builds --ids $WAIT_FOR_BUILD_ID --query 'builds[*].buildStatus' --output text)

    if [[ ! " ${NOT_ACCEPTABLE_PHASES[@]} " =~ " ${BUILD_STATUS} " ]]; then
        echo "Phase is $BUILD_STATUS. Log stream should be available."
        break
    fi

    echo "."

    sleep 5
    done
}

watch_build_logs() {
    BUILD_ID_TO_LOG=$1
    echo "fetching log group for $BUILD_ID_TO_LOG"
    LOG_GROUP=$(aws codebuild batch-get-builds --ids $BUILD_ID_TO_LOG --query 'builds[*].logs.cloudWatchLogs.groupName' --output text)
    LOG_STREAM=$(aws codebuild batch-get-builds --ids $BUILD_ID_TO_LOG --query 'builds[*].logs.cloudWatchLogs.streamName' --output text)

    streamId=$(echo $BUILD_ID_TO_LOG | cut -d ":" -f 2)
    LOG_STREAM_FULL="$LOG_STREAM/$streamId"

    echo "log group for $BUILD_ID_TO_LOG is $LOG_GROUP,  Stream: $LOG_STREAM_FULL"

    awslogs get $LOG_GROUP $LOG_STREAM_FULL --watch --no-group --no-stream | sed '/Phase complete: POST_BUILD/ q'
}
