#!/bin/bash

. $SCRIPTS_DIR/utils.sh

function commitChaincode() {
    local chaincodeName=$1
    local channelName=$2
    local orgNum=$3
    local peerNum=$4

    local chaincodePackagePath="$CHAINCODE_PACKAGE_DIR/${chaincodeName}.tar.gz"
    local peerName="peer${peerId}.${orgType}${orgId}"

    infoln "Commiting chaincode $chaincodeName in channel '$channelName'..."

    parsePeerConnectionParameters $orgNum $peerNum
    infoln "peerConnectionParams: $peerConnectionParams"

    set -x
    peer lifecycle chaincode commit -o $ORDERER_ADDRESS --ordererTLSHostnameOverride $ORDERER_HOSTNAME  --cafile $ORDERER_CA --channelID $channelName --name $chaincodeName --tls $peerConnectionParams --version 1.0 --sequence 1
    res=$?
    { set +x; } 2>/dev/null

    # peer lifecycle chaincode querycommitted --channelID $channelName --name $chaincodeName

}


commitChaincode $1 $2 $3 $4
