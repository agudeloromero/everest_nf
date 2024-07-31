#!/bin/bash
set -uex

# NOTE: Make sure you've set the environment correctly and are logged in to the registry.

CONTAINER_TAG=2.2.4-1
DOCKER_NAMESPACE="ghcr.io/abhi18av"
CONTAINER_NAME="$DOCKER_NAMESPACE/biocontainer-virsorter:$CONTAINER_TAG"
echo "Building container : $CONTAINER_NAME "

#NOTE: When changing the version, update the
#UPSTREAM_CONTAINER="quay.io/biocontainers/ntm-profiler:0.3.0--pyhdfd78af_0"
#docker pull $UPSTREAM_CONTAINER

docker build -t $CONTAINER_NAME .

CONTAINER_ID=$(docker run -d $CONTAINER_NAME)
docker commit $CONTAINER_ID $CONTAINER_NAME
docker push $CONTAINER_NAME
docker stop $CONTAINER_ID
