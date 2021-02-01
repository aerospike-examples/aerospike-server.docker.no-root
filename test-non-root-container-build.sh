#!/bin/bash

NON_ROOT_COMMUNITY_CONTAINER_NAME=non-root-community
NON_ROOT_ENTERPRISE_CONTAINER_NAME=non_root_enterprise

NON_ROOT_COMMUNITY_IMAGE_NAME=aerospike:${NON_ROOT_COMMUNITY_CONTAINER_NAME}
NON_ROOT_ENTERPRISE_IMAGE_NAME=aerospike:${NON_ROOT_ENTERPRISE_CONTAINER_NAME}

# Check community build
docker build -t $NON_ROOT_COMMUNITY_IMAGE_NAME ..
docker run -d --name $NON_ROOT_COMMUNITY_CONTAINER_NAME $NON_ROOT_COMMUNITY_IMAGE_NAME
sleep 5
docker exec -it $NON_ROOT_COMMUNITY_CONTAINER_NAME usr/bin/aql
docker container stop $NON_ROOT_COMMUNITY_CONTAINER_NAME ; docker container rm $NON_ROOT_COMMUNITY_CONTAINER_NAME
docker image rm $NON_ROOT_COMMUNITY_IMAGE_NAME

# Check enterprise build - will fail without a feature key
docker build -t $NON_ROOT_ENTERPRISE_IMAGE_NAME --build-arg IS_ENTERPRISE=1 ..
docker run -d --name $NON_ROOT_ENTERPRISE_CONTAINER_NAME $NON_ROOT_ENTERPRISE_IMAGE_NAME
sleep 5
docker exec -it $NON_ROOT_ENTERPRISE_CONTAINER_NAME usr/bin/aql
docker container stop $NON_ROOT_ENTERPRISE_CONTAINER_NAME ; docker container rm $NON_ROOT_ENTERPRISE_CONTAINER_NAME
docker image rm $NON_ROOT_ENTERPRISE_IMAGE_NAME

# Check enterprise build - will fail without a feature key
docker build -t $NON_ROOT_ENTERPRISE_IMAGE_NAME --build-arg IS_ENTERPRISE=1 --build-arg FEATURE_KEY_FILE=mylicense.conf ..
docker run -d --name $NON_ROOT_ENTERPRISE_CONTAINER_NAME $NON_ROOT_ENTERPRISE_IMAGE_NAME
sleep 5
docker exec -it $NON_ROOT_ENTERPRISE_CONTAINER_NAME usr/bin/aql
docker container stop $NON_ROOT_ENTERPRISE_CONTAINER_NAME ; docker container rm $NON_ROOT_ENTERPRISE_CONTAINER_NAME
docker image rm $NON_ROOT_ENTERPRISE_IMAGE_NAME
