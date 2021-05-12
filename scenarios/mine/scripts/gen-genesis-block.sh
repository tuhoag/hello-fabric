#!/bin/bash

. $PWD/scripts/settings.sh
. $PWD/scripts/init.sh
. $PWD/scripts/utils.sh


function generateGenesisBlock() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    fatalln "configtxgen tool not found."
  fi

  infoln "Generating Orderer Genesis block"

#   cp ./config/configtx.yaml $OUTPUTS/configtx.yaml


  set -x
  configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock $CHANNEL_PATH/genesis.block -configPath $OUTPUT_PATH -configPath $CONFIG_PATH
  res=$?
  { set +x; } 2>/dev/null
  if [ $res -ne 0 ]; then
    fatalln "Failed to generate orderer genesis block..."
  fi
}

generateGenesisBlock