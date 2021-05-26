#!/bin/bash

. $SCRIPTS_DIR/utils.sh

infoln "Stopping the network"

set -x
FABRIC_LOG=INFO COMPOSE_PROJECT_NAME=$PROJECT_NAME PROJECT_NAME=$PROJECT_NAME IMAGE_TAG=$FABRIC_VERSION  docker-compose -f ${DOCKER_COMPOSE_PATH} down -v --rmi all 2>&1
{ set +x; } 2>/dev/null