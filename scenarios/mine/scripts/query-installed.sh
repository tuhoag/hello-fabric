#!/bin/bash

. $SCRIPTS_DIR/utils.sh

function queryInstalled() {
    local orgType=$1
    local orgId=$2
    local peerId=$3
    local peerName="peer${peerId}.${orgType}${orgId}"

    infoln "Getting commited chaincode on $peerName..."
    selectPeer $orgType $orgId $peerId

    set -x
    peer lifecycle chaincode queryinstalled -o $ORDERER_ADDRESS --ordererTLSHostnameOverride $ORDERER_HOSTNAME --cafile $ORDERER_CA --tls >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    cat log.txt
}

queryInstalled $1 $2 $3

