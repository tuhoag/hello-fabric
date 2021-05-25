#!/bin/bash

. $SCRIPTS_DIR/utils.sh

function queryCommitted() {
    local channelName=$1
    local orgType=$2
    local orgId=$3
    local peerId=$4
    local peerName="peer${peerId}.${orgType}${orgId}"

    infoln "Getting commited chaincode on $peerName..."
    selectPeer $orgType $orgId $peerId

    set -x
    peer lifecycle chaincode querycommitted --channelID $channelName -o $ORDERER_ADDRESS --ordererTLSHostnameOverride $ORDERER_HOSTNAME --cafile $ORDERER_CA --tls >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    cat log.txt

    # elif [ $mode = "installed" ]; then
    #     set -x
    #     peer lifecycle chaincode queryinstalled -o $ORDERER_ADDRESS --ordererTLSHostnameOverride $ORDERER_HOSTNAME --cafile $ORDERER_CA --tls >&log.txt
    #     res=$?
    #     { set +x; } 2>/dev/null
    # elif [ $mode = "approved" ]; then
    #     set -x
    #     peer lifecycle chaincode checkcommitreadiness --channelID $channelName --name $chaincodeName --version "1.0" --sequence 1 >&log.txt
    #     res=$?
    #     { set +x; } 2>/dev/null
    # else
    #     errorln "Unsupported MODE: $mode."
    # fi


}

queryCommitted $1 $2 $3 $4 $5

