#!/bin/bash

C_RESET='\033[0m'
C_RED='\033[0;31m'
C_GREEN='\033[0;32m'
C_BLUE='\033[0;34m'
C_YELLOW='\033[1;33m'

# println echos string
function println() {
    echo -e "$1"
}

# errorln echos i red color
function errorln() {
    println "${C_RED}${1}${C_RESET}"
}

# successln echos in green color
function successln() {
    println "${C_GREEN}${1}${C_RESET}"
}

# infoln echos in blue color
function infoln() {
    println "${C_BLUE}${1}${C_RESET}"
}

# warnln echos in yellow color
function warnln() {
    println "${C_YELLOW}${1}${C_RESET}"
}

# fatalln echos in red color and exits with fail status
function fatalln() {
    errorln "$1"
    exit 1
}

function verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}

function selectPeer() {
    local ORG_NAME=$1
    local PEER_NAME=$2
    #   local USING_ORG=""
    #   if [ -z "$OVERRIDE_ORG" ]; then
    #     USING_ORG=$1
    #   else
    #     USING_ORG="${OVERRIDE_ORG}"
    #   fi
    infoln "Selecting organization ${ORG_NAME}'s peer${PEER_NAME}"

    export CORE_PEER_LOCALMSPID="${ORG_NAME}MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${ORGANIZATION_OUTPUTS}/peerOrganizations/${ORG_NAME}.${PROJECT_NAME}.com/peers/peer${PEER_NAME}.${ORG_NAME}.${PROJECT_NAME}.com/tls/ca.crt
    # $PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${ORGANIZATION_OUTPUTS}/peerOrganizations/${ORG_NAME}.${PROJECT_NAME}.com/users/Admin@${ORG_NAME}.${PROJECT_NAME}.com/msp

    if [ $ORG_NAME = "adv1" ]; then
        export CORE_PEER_ADDRESS=localhost:7051
    elif [[ $ORG_NAME = "bus1" ]]; then
        export CORE_PEER_ADDRESS=localhost:9051
    fi

    infoln $CORE_PEER_ADDRESS


    # export CORE_PEER_ADDRESS=localhost:9051

    if [ "$VERBOSE" == "true" ]; then
        env | grep CORE
    fi
}

function getChannelTxPath() {
    channel_name=$1
    channel_tx_path=$CHANNEL_PATH/${channel_name}.tx
    # return $channel_tx_path
}

function getBlockPath() {
    channel_name=$1
    block_path="${CHANNEL_PATH}/${channel_name}.block"
    # return $block_path
}

export -f errorln
export -f successln
export -f infoln
export -f warnln
