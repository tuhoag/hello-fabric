#!/bin/bash

. $SCRIPTS_DIR/utils.sh

function commitChaincode() {
    local chaincodeName=$1
    local channelName=$2
    local orgNum=$3
    local peerNum=$4

    local chaincode_package_path="$CHAINCODE_PACKAGE_DIR/${chaincodeName}.tar.gz"
    local peer_name="peer${peerId}.${orgType}${orgId}"

    infoln "Commiting chaincode $chaincodeName in channel '$channelName'..."

    parsePeerConnectionParameters $orgNum $peerNum

    set -x
    peer lifecycle chaincode commit -o $ORDERER_ADDRESS --ordererTLSHostnameOverride $ORDERER_HOSTNAME  --cafile $ORDERER_CA --channelID $channelName --name $chaincodeName --tls $PEER_CONN_PARMS --version 1.0 --sequence 1 >&log.txt

    { set +x; } 2>/dev/null

    peer lifecycle chaincode querycommitted --channelID $channelName --name $chaincodeName >&log.txt


    # verifyResult $res "Chaincode definition commit failed on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
    # successln "Chaincode definition committed on channel '$CHANNEL_NAME'"
}

function parsePeerConnectionParameters() {
    PEER_CONN_PARMS=""
    for orgType in "adv" "bus"; do
        selectPeer $orgType 0 0

        PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $CORE_PEER_ADDRESS"
        PEER_CONN_PARMS="$PEER_CONN_PARMS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE"
    done
}

commitChaincode $1 $2 $3 $4
