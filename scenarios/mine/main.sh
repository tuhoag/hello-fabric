#!/bin/bash

. $PWD/settings.sh

export CHANNEL_NAME="mychannel"
export LOG_LEVEL=INFO
export FABRIC_LOGGING_SPEC=INFO
export CHAINCODE_NAME="main"

function initialize() {
    # generate all organizations
    $SCRIPTS_DIR/gen-orgs.sh

    # generate genesis-block
    $SCRIPTS_DIR/gen-genesis-block.sh
}

function createChannel() {
    $SCRIPTS_DIR/create-channel-tx.sh $CHANNEL_NAME
    sleep 3
    $SCRIPTS_DIR/create-channel.sh $CHANNEL_NAME "adv" 0
}

function joinChannel() {
    $SCRIPTS_DIR/join-channel.sh $CHANNEL_NAME "adv" 0 0
    $SCRIPTS_DIR/join-channel.sh $CHANNEL_NAME "bus" 0 0
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

function packageChaincode() {
    $SCRIPTS_DIR/package-chaincode.sh $CHAINCODE_NAME
}

function installChaincode() {
    $SCRIPTS_DIR/install-chaincode.sh $CHAINCODE_NAME $CHANNEL_NAME "adv" 0 0
    $SCRIPTS_DIR/install-chaincode.sh $CHAINCODE_NAME $CHANNEL_NAME "bus" 0 0
}

function approveChaincode() {
    $SCRIPTS_DIR/approve-chaincode.sh $CHAINCODE_NAME $CHANNEL_NAME "adv" 0 0
    $SCRIPTS_DIR/approve-chaincode.sh $CHAINCODE_NAME $CHANNEL_NAME "bus" 0 0
}

function commitChaincode() {
    $SCRIPTS_DIR/commit-chaincode.sh $CHAINCODE_NAME $CHANNEL_NAME "adv,bus" 1 1
}

function checkCommitted() {
    $SCRIPTS_DIR/query-committed.sh $CHANNEL_NAME "adv" 0 0
    $SCRIPTS_DIR/query-committed.sh $CHANNEL_NAME "bus" 0 0
}

function checkInstalled() {
    $SCRIPTS_DIR/query-installed.sh "adv" 0 0
    $SCRIPTS_DIR/query-installed.sh "bus" 0 0
}

function checkCommitReadliness() {
    $SCRIPTS_DIR/check-commit-readliness.sh $CHAINCODE_NAME $CHANNEL_NAME "adv" 0 0
    $SCRIPTS_DIR/check-commit-readliness.sh $CHAINCODE_NAME $CHANNEL_NAME "bus" 0 0
}

function listChaincode() {
    $SCRIPTS_DIR/list-chaincode.sh $CHANNEL_NAME "adv" 0 0
    $SCRIPTS_DIR/list-chaincode.sh $CHANNEL_NAME "bus" 0 0
}

function invokeChaincode() {
    # insert a campaign
    # fcn_call='{"function":"'${CC_CREATE_FCN}'","Args":["a1","1","Ken"]}'
    # fcnCall='{"function":"'CreateCampaign'","Args":["'1'","'Campaign1'","'Adv0'","'Bus0'"]}'
    # $SCRIPTS_DIR/invoke-chaincode.sh $CHAINCODE_NAME $CHANNEL_NAME 1 1 $fcnCall

    fcnCall='{"function":"'CreateCampaign'","Args":["'c1'","'Campaign1'","'Adv0'","'Bus0'"]}'
    # fcnCall='{"function":"'ReadAllCampaigns'","Args":[]}'
    # echo "${fcnCall}"
    $SCRIPTS_DIR/invoke-chaincode.sh $CHAINCODE_NAME $CHANNEL_NAME "adv,bus" 1 1 $fcnCall

    #CreateCampaign
}

function invokeQueryChaincode() {
    fcnCall='{"function":"'ReadAllCampaigns'","Args":[]}'
    # fcnCall='{"function":"'ReadAllCampaigns'","Args":[]}'
    # echo "${fcnCall}"
    $SCRIPTS_DIR/invoke-query-chaincode.sh $CHAINCODE_NAME $CHANNEL_NAME "adv" 1 1 $fcnCall
}


MODE=$1

if [ $MODE = "restart" ]; then
    networkDown
    clear
    initialize
    networkUp
    createChannel
    joinChannel
    packageChaincode
    # installChaincode
    # approveChaincode
    # commitChaincode

elif [ $MODE = "init" ]; then
    initialize
elif [ $MODE = "clear" ]; then
    clear
elif [ $MODE = "up" ]; then
    networkUp
elif [ $MODE = "monitor" ]; then
    monitor
elif [ $MODE = "channel" ]; then
    SUB_MODE=$2

    if [ $SUB_MODE = "create" ]; then
        createChannel
    elif [ $SUB_MODE = "join" ]; then
        joinChannel
    else
        echo "Unsupported $MODE $SUB_MODE command."
    fi
elif [ $MODE = "chaincode" ]; then
    SUB_MODE=$2

    if [ $SUB_MODE = "package" ]; then
        packageChaincode
    elif [ $SUB_MODE = "install" ]; then
        installChaincode
    elif [ $SUB_MODE = "approve" ]; then
        approveChaincode
    elif [ $SUB_MODE = "commit" ]; then
        commitChaincode
    elif [ $SUB_MODE = "list" ]; then
        listChaincode
    elif [ $SUB_MODE = "check" ]; then
        SUB_SUB_MODE=$3

        if [ $SUB_SUB_MODE = "installed" ]; then
            checkInstalled
        elif [ $SUB_SUB_MODE = "ready" ]; then
            checkCommitReadliness
        elif [ $SUB_SUB_MODE = "committed" ]; then
            checkCommitted
        else
            echo "Unsuported '$MODE $SUB_MODE $SUB_SUB_MODE' command."
        fi
    elif [ $SUB_MODE = "invoke" ]; then
        invokeChaincode
    elif [ $SUB_MODE = "query" ]; then
        invokeQueryChaincode
    else
        echo "Unsupported '$MODE $SUB_MODE' command."
    fi
else
    echo "Unsupported $MODE command."
fi