#!/bin/bash

. $PWD/scripts/init.sh
. $PWD/scripts/utils.sh

function startNetwork() {
    infoln "Starting the network"

    # COMPOSE_FILE="-f ${COMPOSE_FILE_BASE}"
    # # IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILES} up -d 2>&1

    # PROJECT_NAME=$PROJECT_NAME COMPOSE_PROJECT_NAME=$PROJECT_NAME IMAGE_TAG=$FABRIC_VERSION  docker-compose -f ${DOCKER_COMPOSE_PATH} down -d 2>&1

    PROJECT_NAME=$PROJECT_NAME IMAGE_TAG=$FABRIC_VERSION docker-compose -f ${DOCKER_COMPOSE_PATH} up -d 2>&1

    # echo $IMAGE_TAG

    # docker ps -a
    # if [ $? -ne 0 ]; then
    #     fatalln "Unable to start network"
    # fi
}

startNetwork