#!/bin/bash

. $PWD/scripts/init.sh
. $PWD/scripts/utils.sh


function createConsortium() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    fatalln "configtxgen tool not found."
  fi

  infoln "Generating Orderer Genesis block"

#   cp ./config/configtx.yaml $OUTPUTS/configtx.yaml


  set -x
  configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock $GENESIS_BLOCK_OUTPUTS/genesis.block -configPath ./outputs
  res=$?
  { set +x; } 2>/dev/null
  if [ $res -ne 0 ]; then
    fatalln "Failed to generate orderer genesis block..."
  fi
}