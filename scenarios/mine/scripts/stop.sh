#!/bin/bash

. $PWD/scripts/init.sh
. $PWD/scripts/utils.sh

infoln "Stopping the network"

COMPOSE_PROJECT_NAME=$PROJECT_NAME PROJECT_NAME=$PROJECT_NAME IMAGE_TAG=$FABRIC_VERSION  docker-compose -f ${DOCKER_COMPOSE_PATH} down -v 2>&1