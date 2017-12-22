#!/bin/bash

BUILD_ARGS="$@"
echo "Starting the build with args $BUILD_ARGS"
BUILD_ID=`aws codebuild start-build $BUILD_ARGS --query 'build.id' --output text`
echo "Started build $BUILD_ID"

# The log group is typically not ready right away
sleep 2

# Kick off the log streaming in the background
./codebuild_watch_build_logs.sh "$BUILD_ID" &
LOG_JOB=%1

# Wait for the codebuild to report as anything but IN_PROGRESS
./codebuild_wait_for_finish.sh "$BUILD_ID"

kill $LOG_JOB
