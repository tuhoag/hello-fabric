#!/bin/bash

. $SCRIPTS_DIR/utils.sh

function installChaincode() {
    local chaincodeName=$1
    local channelName=$2
    local orgType=$3
    local orgId=$4
    local peerId=$5
    local chaincodePackagePath="$CHAINCODE_PACKAGE_DIR/${chaincodeName}.tar.gz"
    local peerName="peer${peerId}.${orgType}${orgId}"

    infoln "Installing chaincode ${chaincodeName} in channel ${channelName} of ${peerName}..."

    selectPeer $orgType $orgId $peerId

    packageName="${chaincodeName}_1.0"
    packageId=$(getPackageId $packageName)

    set -x
    packageInfo=$(peer lifecycle chaincode queryinstalled) >&log.txt
    res=$?
    { set +x; } 2>/dev/null

    packageId=$(echo "$packageInfo" | sed -n "s/Package ID: //; s/, Label: ${packageName}$//p")

    if [ -z $packageId ]; then
        # if $packageId is empty, the package is not installed
        infoln "Package ${packageName} is not installed. Installing package ${packageName}..."
        # echo "Empty"
        set -x
        peer lifecycle chaincode install $chaincodePackagePath >&log.txt
        res=$?
        { set +x; } 2>/dev/null
        cat log.txt
        verifyResult $res "Chaincode installation on ${peerName} has failed"
        successln "Chaincode is installed on ${peerName} with id: ${packageId}"
    else
        infoln "Package ${packageName} is installed on ${peerName} with id: ${packageId} and won't be installed again."
    fi
}



installChaincode $1 $2 $3 $4 $5
