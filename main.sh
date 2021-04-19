#!/bin/bash
export OUTPUTS="outputs"
export ORGANIZATION_OUTPUTS=$OUTPUTS/"organizations"
export GENESIS_BLOCK_OUTPUTS=$OUTPUTS/"system-genesis-block"

export PATH=${PWD}/bin:$PATH
export VERBOSE=false
export FABRIC_CFG_PATH=${PWD}/${OUTPUTS}
# temp
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

# function deployChaincode() {

# }

function verifyResult() {
  if [ $1 -ne 0 ]; then
    fatalln "$2"
  fi
}

CC_NAME="hello"
CC_SRC_PATH="${PWD}/chaincode"
CC_VERSION="1.0"
CC_RUNTIME_LANGUAGE="golang"
CC_PACKAGE_FOLDER_OUTPUT="${PWD}/${OUTPUTS}/chaincode"
CC_PACKAGE_FILE_OUTPUT="${CC_PACKAGE_FOLDER_OUTPUT}/${CC_NAME}.tar.gz"

function packageChaincode() {
  infoln "Vendoring Go dependencies at $CC_SRC_PATH"
  pushd $CC_SRC_PATH
  GO111MODULE=on go mod vendor
  popd
  successln "Finished vendoring Go dependencies"

  if [ ! -d $CC_PACKAGE_FOLDER_OUTPUT ]; then
    mkdir $CC_PACKAGE_FOLDER_OUTPUT
  fi

  set -x
  peer lifecycle chaincode package ${CC_PACKAGE_FILE_OUTPUT} --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label ${CC_NAME}_${CC_VERSION} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode packaging has failed"
  successln "Chaincode is packaged"
}

function setGlobals() {
  local USING_ORG=""
  if [ -z "$OVERRIDE_ORG" ]; then
    USING_ORG=$1
  else
    USING_ORG="${OVERRIDE_ORG}"
  fi
  infoln "Using organization ${USING_ORG}"
  if [[ $USING_ORG -eq 1 ]]; then
    export CORE_PEER_LOCALMSPID="Org1MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/${ORGANIZATION_OUTPUTS}/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
    # $PEER0_ORG1_CA
    export CORE_PEER_MSPCONFIGPATH=${PWD}/${ORGANIZATION_OUTPUTS}/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
    export CORE_PEER_ADDRESS=localhost:7051
  elif [[ $USING_ORG -eq 2 ]]; then
    export CORE_PEER_LOCALMSPID="Org2MSP"
    export CORE_PEER_TLS_ROOTCERT_FILE=${PWD}/${ORGANIZATION_OUTPUTS}/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt
    export CORE_PEER_MSPCONFIGPATH=${PWD}/${ORGANIZATION_OUTPUTS}/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
    export CORE_PEER_ADDRESS=localhost:9051

  elif [[ $USING_ORG -eq 3 ]]; then
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

function installChaincode() {
  ORG=$1
  setGlobals $ORG
  set -x
  # FABRIC_CFG_PATH="${PWD}/{}"
  peer lifecycle chaincode install ${CC_PACKAGE_FILE_OUTPUT} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode installation on peer0.org${ORG} has failed"
  successln "Chaincode is installed on peer0.org${ORG}"
}

function queryInstalled() {
  ORG=$1
  setGlobals $ORG
  set -x
  peer lifecycle chaincode queryinstalled >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  export PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)
  verifyResult $res "Query installed on peer0.org${ORG} has failed"
  successln "Query installed successful on peer0.org${ORG} on channel"
  infoln $PACKAGE_ID
}

CC_SEQUENCE=1
# INIT_REQUIRED="--init-required"
# PACKAGE_ID=$(sed -n "/${CC_NAME}_${CC_VERSION}/{s/^Package ID: //; s/, Label:.*$//; p;}" log.txt)

function approveForMyOrg() {
  ORG=$1
  setGlobals $ORG

  set -x
  peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --package-id ${PACKAGE_ID} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode definition approved on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  successln "Chaincode definition approved on peer0.org${ORG} on channel '$CHANNEL_NAME'"
}


checkCommitReadiness() {
  ORG=$1
  shift 1
  setGlobals $ORG
  infoln "Checking the commit readiness of the chaincode definition on peer0.org${ORG} on channel '$CHANNEL_NAME'..."
  local rc=1
  local COUNTER=1
  # continue to poll
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    infoln "Attempting to check the commit readiness of the chaincode definition on peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name ${CC_NAME} --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} --output json >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    let rc=0
    for var in "$@"; do
      grep "$var" log.txt &>/dev/null || let rc=1
    done
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    infoln "Checking the commit readiness of the chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME'"
  else
    fatalln "After $MAX_RETRY attempts, Check commit readiness result on peer0.org${ORG} is INVALID!"
  fi
}

# parsePeerConnectionParameters $@
# Helper function that sets the peer connection parameters for a chaincode
# operation
parsePeerConnectionParameters() {
  PEER_CONN_PARMS=""
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1
    PEER="peer0.org$1"
    ## Set peer addresses
    PEERS="$PEERS $PEER"
    PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $CORE_PEER_ADDRESS"
    ## Set path to TLS certificate
    TLSINFO=$(eval echo "--tlsRootCertFiles $CORE_PEER_TLS_ROOTCERT_FILE")
    PEER_CONN_PARMS="$PEER_CONN_PARMS $TLSINFO"

    infoln "PEERS_CONN_PARMS: ${PEER_CONN_PARMS}"
    infoln "PEERS: ${PEERS}"
    # shift by one to get to the next organization
    shift
  done
  # remove leading space for output
  PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"
}

# commitChaincodeDefinition VERSION PEER ORG (PEER ORG)...
commitChaincodeDefinition() {
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  set -x
  peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name ${CC_NAME} $PEER_CONN_PARMS --version ${CC_VERSION} --sequence ${CC_SEQUENCE} ${INIT_REQUIRED} ${CC_END_POLICY} ${CC_COLL_CONFIG} >&log.txt
  res=$?
  { set +x; } 2>/dev/null
  cat log.txt
  verifyResult $res "Chaincode definition commit failed on peer0.org${ORG} on channel '$CHANNEL_NAME' failed"
  successln "Chaincode definition committed on channel '$CHANNEL_NAME'"
}

queryCommitted() {
  ORG=$1
  setGlobals $ORG
  EXPECTED_RESULT="Version: ${CC_VERSION}, Sequence: ${CC_SEQUENCE}, Endorsement Plugin: escc, Validation Plugin: vscc"
  infoln "Querying chaincode definition on peer0.org${ORG} on channel '$CHANNEL_NAME'..."
  local rc=1
  local COUNTER=1
  # continue to poll
  # we either get a successful response, or reach MAX RETRY
  while [ $rc -ne 0 -a $COUNTER -lt $MAX_RETRY ]; do
    sleep $DELAY
    infoln "Attempting to Query committed status on peer0.org${ORG}, Retry after $DELAY seconds."
    set -x
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name ${CC_NAME} >&log.txt
    res=$?
    { set +x; } 2>/dev/null
    test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: '$CC_VERSION', Sequence: [0-9]*, Endorsement Plugin: escc, Validation Plugin: vscc')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
    COUNTER=$(expr $COUNTER + 1)
  done
  cat log.txt
  if test $rc -eq 0; then
    successln "Query chaincode definition successful on peer0.org${ORG} on channel '$CHANNEL_NAME'"
  else
    fatalln "After $MAX_RETRY attempts, Query chaincode definition result on peer0.org${ORG} is INVALID!"
  fi
}

function deployCC() {
  # generate packages
  packageChaincode

  # install chaincode
  installChaincode 1
  installChaincode 2

  queryInstalled 1
  queryInstalled 2

  approveForMyOrg 1

  ## check whether the chaincode definition is ready to be committed
  ## expect org1 to have approved and org2 not to
  checkCommitReadiness 1 "\"Org1MSP\": true" "\"Org2MSP\": false"
  checkCommitReadiness 2 "\"Org1MSP\": true" "\"Org2MSP\": false"

  approveForMyOrg 2

  ## check whether the chaincode definition is ready to be committed
  ## expect them both to have approved
  checkCommitReadiness 1 "\"Org1MSP\": true" "\"Org2MSP\": true"
  checkCommitReadiness 2 "\"Org1MSP\": true" "\"Org2MSP\": true"

  # now that we know for sure both orgs have approved, commit the definition
  commitChaincodeDefinition 1 2

  queryCommitted 1
  queryCommitted 2
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
elif [ "$MODE" == "deployCC" ]; then
  deployCC
  # installChaincode
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