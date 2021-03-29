#!/bin/bash

export PATH=${PWD}/bin:$PATH
export FABRIC_CFG_PATH=${PWD}/configtx
export VERBOSE=false

. utils.sh

export OUTPUTS="outputs"
export ORGANIZATION_OUTPUTS=$OUTPUTS/"organizations"
export GENESIS_BLOCK_OUTPUTS=$OUTPUTS/"system-genesis-block"

# generate certificates using cryptogen
function createOrgs() {
    # check cryptogen
    which cryptogen
    if [ "$?" -ne 0 ]; then
        fatalln "cryptogen tool not found. exiting"
    fi
    infoln "Generating certificates using cryptogen tool"

    # generate orgs identities
    infoln "Creating Org1 Identities"
    set -x
    cryptogen generate --config=./organizations/crypto-config-org1.yaml --output=$ORGANIZATION_OUTPUTS
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then
      fatalln "Failed to generate certificates..."
    fi

    infoln "Creating Org2 Identities"
    set -x
    cryptogen generate --config=./organizations/crypto-config-org2.yaml --output=$ORGANIZATION_OUTPUTS
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then
      fatalln "Failed to generate certificates..."
    fi


    infoln "Creating Org2 Identities"
    set -x
    cryptogen generate --config=./organizations/crypto-config-orderer.yaml --output=$ORGANIZATION_OUTPUTS
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then
      fatalln "Failed to generate certificates..."
    fi


    # maybe we need to generate ccp files
}


# generate genesis block using configtxgen
function createConsortium() {
    which configtxgen
    if [ "$?" -ne 0 ]; then
        fatalln "configtxgen tool not found."
    fi

    infoln "Generating Orderer Genesis block"

    set -x
    configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock $GENESIS_BLOCK_OUTPUTS/genesis.block
    res=$?
    { set +x; } 2>/dev/null
    if [ $res -ne 0 ]; then
        fatalln "Failed to generate orderer genesis block..."
    fi
}


createOrgs
createConsortium