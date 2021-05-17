#!/bin/bash

. $PWD/scripts/init.sh
. $PWD/scripts/utils.sh
. $PWD/scripts/settings.sh

function startNetwork() {
    infoln "Starting the network"
    infoln $FABRIC_CFG_PATH

    COMPOSE_PROJECT_NAME=$PROJECT_NAME PROJECT_NAME=$PROJECT_NAME IMAGE_TAG=$FABRIC_VERSION docker-compose -f ${DOCKER_COMPOSE_PATH} up -d 2>&1

    docker ps -a
    if [ $? -ne 0 ]; then
        fatalln "Unable to start network"
    fi
}

startNetwork