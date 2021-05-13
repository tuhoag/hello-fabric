#!/bin/bash

function startNetwork()
    infoln "Starting the network"

    COMPOSE_FILE="-f ${COMPOSE_FILE_BASE}"
    # IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILES} up -d 2>&1

    IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILE} up -d 2>&1

    echo $IMAGE_TAG

    docker ps -a
    if [ $? -ne 0 ]; then
        fatalln "Unable to start network"
    fi

startNetwork