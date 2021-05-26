#!/bin/bash

. $SCRIPTS_DIR/utils.sh

function invokeQueryChaincode() {
    # ORG=$1
    # setGlobals $ORG
    # infoln "Querying on peer0.org${ORG} on channel '$CHANNEL_NAME'..."

    # local rc=1
    # local COUNTER=1
    # # continue to poll
    # # we either get a successful response, or reach MAX RETRY
    # while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    #     sleep $DELAY
    #     infoln "Attempting to Query peer0.org${ORG}, Retry after $DELAY seconds."
    #     set -x
    #     peer chaincode query -C $CHANNEL_NAME -n ${CC_NAME} -c '{"Args":["'${CC_READ_ALL_FCN}'"]}' >&log.txt
    #     res=$?
    #     { set +x; } 2>/dev/null
    #     let rc=$res
    #     COUNTER=$(expr $COUNTER + 1)
    # done
    # cat log.txt
    # if test $rc -eq 0; then
    #     successln "Query successful on peer0.org${ORG} on channel '$CHANNEL_NAME'"
    # else
    #     fatalln "After $MAX_RETRY attempts, Query result on peer0.org${ORG} is INVALID!"
    # fi


    local chaincodeName=$1
    local channelName=$2
    local orgType=$3
    local orgNum=$4
    local peerNum=$5
    local fcnCall=$6

    infoln $orgType

    parsePeerConnectionParameters $orgType $orgNum $peerNum

    infoln "Invoke fcn call:${fcnCall} on peers: $peers"

    set -x
    peer chaincode query --channelID $channelName --name $chaincodeName -o $ORDERER_ADDRESS --ordererTLSHostnameOverride $ORDERER_HOSTNAME --cafile $ORDERER_CA --tls $peerConnectionParams -c $fcnCall >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    cat log.txt
    verifyResult $res "Invoke execution on $peers failed "
    successln "Invoke transaction successful on $peers on channel '$channelName'"

}

invokeQueryChaincode $1 $2 $3 $4 $5 $6
