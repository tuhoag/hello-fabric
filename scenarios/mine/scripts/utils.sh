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
    local orgType=$1
    local orgId=$2
    local peerId=$3

    # calculate port
    if [ $orgType = "adv" ]; then
        local basePort=$ADV_BASE_PORT
    elif [ $orgType = "bus" ]; then
        local basePort=$BUS_BASE_PORT
    else
        errorln "Org type $orgType is unsupported."
    fi
    local port=$(($basePort + $orgId * 100 + $peerId))
    local orgName="${orgType}${orgId}"
    local orgDomain="${orgName}.${PROJECT_NAME}.com"
    local peerDomain="peer${peerId}.${orgDomain}"

    infoln "Selecting organization ${peerDomain} with port $port"

    export CORE_PEER_TLS_ENABLED=true
    export CORE_PEER_LOCALMSPID="${orgName}MSP"
    export CORE_PEER_ADDRESS="0.0.0.0:${port}"
    export PEER_ORG_CA="${ORGANIZATION_OUTPUTS}/peerOrganizations/$orgDomain/peers/$peerDomain/tls/ca.crt"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER_ORG_CA
    export CORE_PEER_MSPCONFIGPATH="${ORGANIZATION_OUTPUTS}/peerOrganizations/${orgDomain}/users/Admin@${orgDomain}/msp"

    infoln "Selected peer ${peerDomain}: ${CORE_PEER_MSPCONFIGPATH}"
}

function getChannelTxPath() {
    echo $CHANNEL_PATH/$1.tx
}

function getBlockPath() {
    echo "${CHANNEL_PATH}/$1.block"
}

function getPackageId() {
    # packageInfo=$1
    packageName=$1
    set -x
    packageInfo=$(peer lifecycle chaincode queryinstalled) >&log.txt
    res=$?
    packageId=$(echo "$packageInfo" | sed -n "s/Package ID: ${packageName}:*//; s/, Label: ${packageName}$//p")
    { set +x; } 2>/dev/null


    echo "${packageName}:${packageId}"
}


function parsePeerConnectionParameters() {
    IFS=',' read -r -a orgTypes <<< $1
    local maxOrdId=$(($2 - 1))
    local maxPeerId=$(($3 - 1))

    peerConnectionParams=""
    peers=""
    for orgType in ${orgTypes[@]}; do
        for orgId in $(seq 0 $maxOrdId); do
            for peerId in $(seq 0 $maxOrdId); do
                selectPeer $orgType $orgId $peerId

                peers="$peers $CORE_PEER_ADDRESS"
                peerConnectionParams="$peerConnectionParams --peerAddresses $CORE_PEER_ADDRESS"
                peerConnectionParams="$peerConnectionParams --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE"
            done
        done
    done
}


export -f errorln
export -f successln
export -f infoln
export -f warnln
