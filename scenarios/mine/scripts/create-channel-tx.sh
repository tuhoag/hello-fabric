#!/bin/bash

. $SCRIPTS_DIR/utils.sh

function createChannelTx() {
    channelName=$1
	local channelTxPath=$(getChannelTxPath $channelName)

    infoln $channelName
    infoln $channelTxPath
	set -x
	configtxgen -profile TwoOrgsChannel -outputCreateChannelTx $channelTxPath -channelID $channelName -configPath $CONFIG_PATH
	res=$?
	{ set +x; } 2>/dev/null

    verifyResult $res "Failed to generate channel configuration transaction..."
}

createChannelTx $1