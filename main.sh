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
IMAGETAG="latest"

function startNetwork() {
  infoln "Starting the network"

  COMPOSE_FILE="-f ${COMPOSE_FILE_BASE}"
  # IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILES} up -d 2>&1

  IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILE} up -d 2>&1

  echo $IMAGE_TAG

  docker ps -a
  if [ $? -ne 0 ]; then
    fatalln "Unable to start network"
  fi
}

function stopNetwork() {
  infoln "Stopping the network"

  COMPOSE_FILE="-f ${COMPOSE_FILE_BASE}"
  IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILE} down 2>&1
}

function clearOutputs() {
  rm -rf $OUTPUTS
}

CHANNEL_NAME="mychannel"
DELAY="3"
MAX_RETRY="5"
VERBOSE="false"
# : ${CHANNEL_NAME:="mychannel"}
# : ${DELAY:="3"}
# : ${MAX_RETRY:="5"}
# : ${VERBOSE:="false"}


function createChannelTx() {
  if [ ! -d "channel-artifacts" ]; then
    mkdir channel-artifacts
  fi

  # infoln $CHANNEL_NAME
  # infoln $DELAY
  # infoln $MAX_RETRY
  # infoln $VERBOSE

	set -x
	configtxgen -profile TwoOrgsChannel -outputCreateChannelTx $OUTPUTS/channel-artifacts/${CHANNEL_NAME}.tx -channelID $CHANNEL_NAME -configPath $OUTPUTS
	res=$?
	{ set +x; } 2>/dev/null
  verifyResult $res "Failed to generate channel configuration transaction..."
}

function createChannel() {
  setGlobals 1
	# Poll in case the raft leader is not set yet
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
		set -x
		peer channel create -o localhost:7050 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.example.com -f ./channel-artifacts/${CHANNEL_NAME}.tx --outputBlock $BLOCKFILE --tls --cafile $ORDERER_CA >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
}

function verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}


# clearOutputs
# createOrgs
# createConsortium
# startNetwork
createChannelTx
createChannel
# stopNetwork