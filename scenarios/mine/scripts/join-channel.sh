#!/bin/bash

. $SCRIPTS_DIR/utils.sh

function joinChannel() {
    local channelName=$1
    local orgType=$2
    local orgId=$3
    local peerId=$4

    local orgName="${orgType}${orgId}"

    infoln "Joining Channel $channelName from peer${peerId}.${orgName}"

    selectPeer $orgType $orgId $peerId

    local blockPath=$(getBlockPath $channelName)

    # peer channel getinfo -c $channelName

    set -x
    peer channel join -o $ORDERER_ADDRESS --ordererTLSHostnameOverride $ORDERER_HOSTNAME --tls --cafile $ORDERER_CA -b $blockPath
    res=$?
    { set +x; } 2>/dev/null

    verifyResult $res "Cannot join $channelName from peer${peerId}.${orgName}"
}

joinChannel $1 $2 $3 $4