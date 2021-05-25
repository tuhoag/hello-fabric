#!/bin/bash

. $SCRIPTS_DIR/utils.sh

function invokeChaincode() {
    local chaincodeName=$1
    local channelName=$2
    local orgNum=$3
    local peerNum=$4
    local fcnCall=$5

    parsePeerConnectionParameters $orgNum $peerNum

    infoln "Invoke fcn call:${fcnCall} on peers: $peers"

    set -x
    peer chaincode invoke --channelID $channelName --name $chaincodeName -o $ORDERER_ADDRESS --ordererTLSHostnameOverride $ORDERER_HOSTNAME --cafile $ORDERER_CA --tls $peerConnectionParams -c $fcnCall >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    cat log.txt
    verifyResult $res "Invoke execution on $peers failed "
    successln "Invoke transaction successful on $peers on channel '$channelName'"

}



# getChaincodeList $1 $2 $3 $4 $5
invokeChaincode $1 $2 $3 $4 $5
