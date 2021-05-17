#!/bin/bash

. $PWD/scripts/init.sh
. $PWD/scripts/utils.sh

function joinChannel() {
    local channel_name=$1
    local org_name=$2
    local peer=$3

    infoln "Joining Channel ${channel_name} from Org ${org_name}'s peer${peer}"


    local MAX_RETRY=3
    local DELAY="3"
    local MAX_RETRY="2"
    local VERBOSE="false"
    local rc=1
	local COUNTER=1

    selectPeer $org_name $peer
    getBlockPath $channel_name
    # local block_path="${CHANNEL_PATH}/${channel_name}.block"

    # infoln $CORE_PEER_TLS_ROOTCERT_FILE

	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
        sleep $DELAY
        set -x
        peer channel join -b $block_path -o localhost:7050 --ordererTLSHostnameOverride orderer.$PROJECT_NAME.com --tls --cafile $ORDERER_CA >&log.txt
        res=$?
        { set +x; } 2>/dev/null
        let rc=$res
        COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "After $MAX_RETRY attempts, peer${peer}.${org_name}.promark.com has failed to join channel '${channel_name}'"
}

joinChannel $1 $2 $3