#!/bin/bash

echo $1

BUILD_ID=$1

while :
do

BUILD_STATUS=`aws codebuild batch-get-builds --ids $BUILD_ID --query 'builds[*].buildStatus' --output text`

if [ $BUILD_STATUS != 'IN_PROGRESS' ]
then
	echo "Build finished with result $BUILD_STATUS"
	break #Abandon the loop.
fi

sleep 10
done