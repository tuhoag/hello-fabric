#!/bin/bash
export OUTPUTS="outputs"
export ORGANIZATION_OUTPUTS=$OUTPUTS/"organizations"
export GENESIS_BLOCK_OUTPUTS=$OUTPUTS/"system-genesis-block"

export PATH=${PWD}/bin:$PATH
export VERBOSE=false

. utils.sh

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

  cp ./configtx/configtx.yaml $OUTPUTS/configtx.yaml

  set -x
  configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock $GENESIS_BLOCK_OUTPUTS/genesis.block -configPath $OUTPUTS
  res=$?
  { set +x; } 2>/dev/null
  if [ $res -ne 0 ]; then
    fatalln "Failed to generate orderer genesis block..."
  fi
}

COMPOSE_FILE_BASE=docker/docker-compose-test-net.yaml
IMAGE_TAG="latest"

function startNetwork() {
  infoln "Starting the network"

  COMPOSE_FILE="-f ${COMPOSE_FILE_BASE}"
  # IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILES} up -d 2>&1

  docker-compose ${COMPOSE_FILE} up -d 2>&1

  echo $IMAGE_TAG

  docker ps -a
  if [ $? -ne 0 ]; then
    fatalln "Unable to start network"
  fi
}

function stopNetwork() {
  infoln "Stopping the network"

  COMPOSE_FILE="-f ${COMPOSE_FILE_BASE}"
  docker-compose ${COMPOSE_FILE} down 2>&1
}

function clearOutputs() {
  rm -rf $OUTPUTS
}

clearOutputs
createOrgs
createConsortium
startNetwork
stopNetwork