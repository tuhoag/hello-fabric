#!/bin/bash

. $PWD/scripts/settings.sh
. $PWD/scripts/init.sh
. $PWD/scripts/utils.sh


function createChannel() {
    local org_name=$1
    local channel_name=$2
    local MAX_RETRY=3
    local DELAY="3"
    local MAX_RETRY="2"
    local VERBOSE="false"

    selectPeer $org_name 0

    getChannelTxPath $channel_name
    getBlockPath $channel_name

	local rc=1
	local num_tries=1
	while [ $rc -ne 0 -a $num_tries -lt $MAX_RETRY ] ; do
		sleep $DELAY

		set -x
		peer channel create -o localhost:7050 -c $channel_name --ordererTLSHostnameOverride orderer.$PROJECT_NAME.com -f $channel_tx_path --outputBlock $block_path --tls --cafile $ORDERER_CA >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		num_tries=$(expr $num_tries + 1)
	done
	# cat log.txt
	verifyResult $res "Channel creation failed"
}

ORG_NAME=$1
CHANNEL_NAME=$2

createChannel $ORG_NAME $CHANNEL_NAME