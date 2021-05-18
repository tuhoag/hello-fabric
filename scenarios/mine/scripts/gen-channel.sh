#!/bin/bash

. $SCRIPTS_DIR/utils.sh


function createChannel() {
    local channel_name=$1
    local org_type=$2
    local org_id=$3

    selectPeer $org_type $org_id 0

    println "Generating channel tx..."
    getChannelTxPath $channel_name
    getBlockPath $channel_name

    println "Creating channel..."
    peer channel create -o $ORDERER_ADDRESS --ordererTLSHostnameOverride $ORDERER_HOSTNAME -c $channel_name -f $channel_tx_path --outputBlock $block_path --tls --cafile $ORDERER_CA


	# cat log.txt
	# verifyResult $res "Channel creation failed"
}

createChannel $1 $2 $3