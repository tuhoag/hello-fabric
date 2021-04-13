#!/bin/bash
export OUTPUTS="outputs"
export ORGANIZATION_OUTPUTS=$OUTPUTS/"organizations"
export GENESIS_BLOCK_OUTPUTS=$OUTPUTS/"system-genesis-block"

export PATH=${PWD}/bin:$PATH
export VERBOSE=false
export FABRIC_CFG_PATH=$OUTPUTS

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

  cp ./config/configtx.yaml $OUTPUTS/configtx.yaml


  set -x
  configtxgen -profile TwoOrgsOrdererGenesis -channelID system-channel -outputBlock $GENESIS_BLOCK_OUTPUTS/genesis.block -configPath ./outputs
  res=$?
  { set +x; } 2>/dev/null
  if [ $res -ne 0 ]; then
    fatalln "Failed to generate orderer genesis block..."
  fi
}

COMPOSE_FILE_BASE=docker/docker-compose-test-net.yaml
IMAGETAG="2.2.2"

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

  # docker-compose -f $COMPOSE_FILE_BASE -f $COMPOSE_FILE_COUCH -f $COMPOSE_FILE_CA down --volumes --remove-orphans
  # docker-compose -f $COMPOSE_FILE_COUCH_ORG3 -f $COMPOSE_FILE_ORG3 down --volumes --remove-orphans
  # # Don't remove the generated artifacts -- note, the ledgers are always removed
  # if [ "$MODE" != "restart" ]; then
  #   # Bring down the network, deleting the volumes
  #   #Cleanup the chaincode containers
  #   clearContainers
  #   #Cleanup images
  #   removeUnwantedImages
  #   # remove orderer block and other channel configuration transactions and certs
  #   docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf system-genesis-block/*.block organizations/peerOrganizations organizations/ordererOrganizations'
  #   ## remove fabric ca artifacts
  #   docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/org1/msp organizations/fabric-ca/org1/tls-cert.pem organizations/fabric-ca/org1/ca-cert.pem organizations/fabric-ca/org1/IssuerPublicKey organizations/fabric-ca/org1/IssuerRevocationPublicKey organizations/fabric-ca/org1/fabric-ca-server.db'
  #   docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/org2/msp organizations/fabric-ca/org2/tls-cert.pem organizations/fabric-ca/org2/ca-cert.pem organizations/fabric-ca/org2/IssuerPublicKey organizations/fabric-ca/org2/IssuerRevocationPublicKey organizations/fabric-ca/org2/fabric-ca-server.db'
  #   docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf organizations/fabric-ca/ordererOrg/msp organizations/fabric-ca/ordererOrg/tls-cert.pem organizations/fabric-ca/ordererOrg/ca-cert.pem organizations/fabric-ca/ordererOrg/IssuerPublicKey organizations/fabric-ca/ordererOrg/IssuerRevocationPublicKey organizations/fabric-ca/ordererOrg/fabric-ca-server.db'
  #   docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf addOrg3/fabric-ca/org3/msp addOrg3/fabric-ca/org3/tls-cert.pem addOrg3/fabric-ca/org3/ca-cert.pem addOrg3/fabric-ca/org3/IssuerPublicKey addOrg3/fabric-ca/org3/IssuerRevocationPublicKey addOrg3/fabric-ca/org3/fabric-ca-server.db'
  #   # remove channel and script artifacts
  #   docker run --rm -v $(pwd):/data busybox sh -c 'cd /data && rm -rf channel-artifacts log.txt *.tar.gz'
  # fi

  COMPOSE_FILE="-f ${COMPOSE_FILE_BASE}"
  IMAGE_TAG=$IMAGETAG docker-compose ${COMPOSE_FILE} down --volumes --remove-orphans 2>&1
}

function clearOutputs() {
  rm -rf $OUTPUTS
}

FABRIC_LOGGING_SPEC=DEBUG
CHANNEL_NAME="mychannel1"
DELAY="3"
MAX_RETRY="2"
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

export ORDERER_CA=${PWD}/outputs/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CORE_PEER_TLS_ENABLED=true
# export USING_ORG=2
# export CORE_PEER_LOCALMSPID="Org2MSP"
# export CORE_PEER_ADDRESS=localhost:9051
# export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/outputs/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
# export CORE_PEER_MSPCONFIGPATH=${PWD}/outputs/organizations/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp

BLOCKFILE="${OUTPUTS}/channel-artifacts/${CHANNEL_NAME}.block"

function createChannel() {
  setGlobals 1
  cp ./config/core.yaml $OUTPUTS/core.yaml
  FABRIC_CFG_PATH=${PWD}/outputs/
  infoln $FABRIC_CFG_PATH
  infoln $CORE_PEER_MSPCONFIGPATH
	# Poll in case the raft leader is not set yet
	local rc=1
	local COUNTER=1
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
		sleep $DELAY
    infoln "-f ${OUTPUT}/channel-artifacts/${CHANNEL_NAME}.tx"
		set -x
		peer channel create -o localhost:7050 -c $CHANNEL_NAME --ordererTLSHostnameOverride orderer.example.com -f ./outputs/channel-artifacts/${CHANNEL_NAME}.tx --outputBlock $BLOCKFILE --tls --cafile $ORDERER_CA >&log.txt
		res=$?
		{ set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "Channel creation failed"
}


function joinChannel() {
  FABRIC_CFG_PATH=$OUTPUTS
  ORG=$1
  setGlobals $ORG
	local rc=1
	local COUNTER=1
	## Sometimes Join takes time, hence retry
	while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ] ; do
    sleep $DELAY
    set -x
    peer channel join -b $BLOCKFILE >&log.txt
    res=$?
    { set +x; } 2>/dev/null
		let rc=$res
		COUNTER=$(expr $COUNTER + 1)
	done
	cat log.txt
	verifyResult $res "After $MAX_RETRY attempts, peer0.org${ORG} has failed to join channel '$CHANNEL_NAME' "
}

function verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}

function setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  infoln "Using organization ${USING_ORG}"
  if [ $USING_ORG -eq 1 ]; then
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/${ORGANIZATION_OUTPUTS}/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
    # $PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/${ORGANIZATION_OUTPUTS}/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [ $USING_ORG -eq 2 ]; then
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/${ORGANIZATION_OUTPUTS}/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=${PWD}/${ORGANIZATION_OUTPUTS}/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    export CORE_PEER_ADDRESS=localhost:9051

  elif [ $USING_ORG -eq 3 ]; then
    export CORE_PEER_LOCALMSPID="Org3MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=$PEER0_ORG3_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/${ORGANIZATION_OUTPUTS}/peerOrganizations/org3.example.com/users/Admin@org3.example.com/msp
    export CORE_PEER_ADDRESS=localhost:11051
  else
    errorln "ORG Unknown"
  fi

  if [ "$VERBOSE" == "true" ]; then
    env | grep CORE
  fi
}



# Parse commandline args

## Parse mode
if [[ $# -lt 1 ]] ; then
  printHelp
  exit 0
else
  MODE=$1
  shift
fi


if [ "$MODE" == "test" ]; then
  infoln "Starting nodes with CLI timeout of '${MAX_RETRY}' tries and CLI delay of '${CLI_DELAY}' seconds and using database '${DATABASE}' ${CRYPTO_MODE}"
  clearOutputs
  createOrgs
  createConsortium
  startNetwork
  createChannelTx
  createChannel
  stopNetwork
elif [ "$MODE" == "createOrgs" ]; then
  createOrgs
  createConsortium
elif [ "$MODE" == "up" ]; then
  createOrgs
  createConsortium
  startNetwork

elif [ "$MODE" == "createChannel" ]; then
  createChannelTx
  createChannel
  # setGlobals 1
  joinChannel 1
  # setGlobals 2
  joinChannel 2
elif [ "$MODE" == "down" ]; then
  stopNetwork
  clearOutputs
elif [ "$MODE" == "clean" ]; then
  clearOutputs
fi

# clearOutputs
# createOrgs
# createConsortium
# startNetwork
# createChannelTx
# createChannel
# stopNetwork