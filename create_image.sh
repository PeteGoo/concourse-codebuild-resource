#!/usr/bin/env bash

REPO=$1
TAG=$2

docker build -t $REPO:latest .
docker push $REPO:latest
docker tag $REPO:latest $REPO:$TAG
docker push $REPO:$TAG
