#!/bin/bash

. $SCRIPTS_DIR/utils.sh

function getChaincodeList() {
    local channelName=$1
    local orgType=$2
    local orgId=$3
    local peerId=$4
    local chaincodePackagePath="$CHAINCODE_PACKAGE_DIR/${chaincodeName}.tar.gz"
    local peerName="peer${peerId}.${orgType}${orgId}"

    infoln "Getting list of installed chaincode..."
    selectPeer $orgType $orgId $peerId

    set -x
    peer chaincode list --channelID $channelName --installed -o $ORDERER_ADDRESS --ordererTLSHostnameOverride $ORDERER_HOSTNAME --cafile $ORDERER_CA --tls >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    cat log.txt

    selectPeer "bus" 0 0

    infoln "Getting list of inistatied chaincode..."
    set -x
    peer chaincode list --channelID $channelName --instantiated -o $ORDERER_ADDRESS --ordererTLSHostnameOverride $ORDERER_HOSTNAME --cafile $ORDERER_CA --tls >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    cat log.txt
}

getChaincodeList $1 $2 $3 $4