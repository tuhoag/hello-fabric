#!/bin/bash

. $PWD/settings.sh

export CHANNEL_NAME="my_channel"
export LOG_LEVEL=INFO
export FABRIC_LOGGING_SPEC=DEBUG

function initialize() {
    # generate all organizations
    $SCRIPTS_DIR/gen-orgs.sh

    # generate genesis-block
    $SCRIPTS_DIR/gen-genesis-block.sh
}

function createChannel() {
    $SCRIPTS_DIR/gen-channel-tx.sh "mychannel"
    $SCRIPTS_DIR/gen-channel.sh "mychannel" "adv" 0
}

function networkUp() {
    $SCRIPTS_DIR/start.sh $LOG_LEVEL
}

function networkDown() {
    # docker rm -f logspout

    $SCRIPTS_DIR/stop.sh $LOG_LEVEL
}

function clear() {
    $SCRIPTS_DIR/clear.sh
}

function monitor() {
    $SCRIPTS_DIR/monitor.sh
}

MODE=$1

if [ $MODE = "restart" ]; then
    networkDown
    clear
    initialize
    networkUp
    createChannel

elif [ $MODE = "init" ]; then
    initialize
elif [ $MODE = "clear" ]; then
    clear
elif [ $MODE = "up" ]; then
    networkUp
elif [ $MODE = "monitor" ]; then
    monitor
elif [ $MODE = "channel" ]; then
    createChannel
fi