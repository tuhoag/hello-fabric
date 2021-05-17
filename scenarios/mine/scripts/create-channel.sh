#!/bin/bash

. $PWD/scripts/settings.sh
. $PWD/scripts/init.sh
. $PWD/scripts/utils.sh


function createChannel() {
    selectPeer "adv1" 0

    local channel_name=$1
    local MAX_RETRY=3
    local DELAY="3"
    local MAX_RETRY="2"
    local VERBOSE="false"
    # # cp ./config/core.yaml $OUTPUTS/core.yaml
    # FABRIC_CFG_PATH=${PWD}/outputs/
    # # infoln $FABRIC_CFG_PATH
    # # infoln $CORE_PEER_MSPCONFIGPATH
	# Poll in case the raft leader is not set yet
    getChannelTxPath $channel_name
    getBlockPath $channel_name

    infoln $channel_tx_path
    infoln $block_path
    infoln $FABRIC_CFG_PATH
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

CHANNEL_NAME=$1

createChannel $CHANNEL_NAME