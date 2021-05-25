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
    local peerConnectionParams=$res
    infoln "peerConnectionParams: $peerConnectionParams"
    infoln "PEER_CONN_PARAMS: $PEER_CONN_PARMS"

    set -x
    peer lifecycle chaincode commit -o $ORDERER_ADDRESS --ordererTLSHostnameOverride $ORDERER_HOSTNAME  --cafile $ORDERER_CA --channelID $channelName --name $chaincodeName --tls $PEER_CONN_PARMS --version 1.0 --sequence 1
    res=$?
    { set +x; } 2>/dev/null

    peer lifecycle chaincode querycommitted --channelID $channelName --name $chaincodeName

    # verifyResult $res "Chaincode definition commit failed on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
    # successln "Chaincode definition committed on channel '$CHANNEL_NAME'"
}

function parsePeerConnectionParameters() {
    local maxOrdId=$(($1 - 1))
    local maxPeerId=$(($2 - 1))

    PEER_CONN_PARMS=""
    for orgType in "adv" "bus"; do
        for orgId in $(seq 0 $maxOrdId); do
            for peerId in $(seq 0 $maxOrdId); do
                selectPeer $orgType $orgId $peerId

                PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $CORE_PEER_ADDRESS"
                PEER_CONN_PARMS="$PEER_CONN_PARMS --tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE"
            done
        done
    done

    res=$PEER_CONN_PARMS
    echo $res
}

commitChaincode $1 $2 $3 $4
