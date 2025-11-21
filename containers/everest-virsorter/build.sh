#!/bin/bash
set -uex

# NOTE: Make sure you've set the environment correctly and are logged in to the registry.

CONTAINER_TAG=2.2.4-1
DOCKER_NAMESPACE="ghcr.io/abhi18av"

CONTAINER_NAME="$DOCKER_NAMESPACE/everest-virsorter:$CONTAINER_TAG"

echo "Building container : $CONTAINER_NAME "


docker build -t $CONTAINER_NAME .
CONTAINER_ID=$(docker run -d $CONTAINER_NAME)
docker commit $CONTAINER_ID $CONTAINER_NAME
docker push $CONTAINER_NAME
docker stop $CONTAINER_ID
