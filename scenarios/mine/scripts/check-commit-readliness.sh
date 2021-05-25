#!/bin/bash

. $SCRIPTS_DIR/utils.sh

function checkCommitReadiness() {
    local chaincodeName=$1
    local channelName=$2
    local orgType=$3
    local orgId=$4
    local peerId=$5
    local chaincode_package_path="$CHAINCODE_PACKAGE_DIR/${chaincodeName}.tar.gz"
    local peerName="peer${peerId}.${orgType}${orgId}"

    infoln "Checking chaincode ${chaincodeName}'s approval in channel ${channelName} of ${peerName}..."

    selectPeer $orgType $orgId $peerId

    packageName="${chaincodeName}_1.0"
    packageId=$(getPackageId $packageName)

    set -x
    peer lifecycle chaincode checkcommitreadiness --channelID $channelName --name $chaincodeName --version "1.0" --sequence 1 >&log.txt
    { set +x; } 2>/dev/null

    cat log.txt
    # result=$(echo $result | grep -q "${CORE_PEER_LOCALMSPID}: true")
    # echo $result
    # if [[ ! -z $result ]]; then
    #     echo "true"
    # else
    #     echo "false"
    # fi
}

checkCommitReadiness $1 $2 $3 $4 $5
