#!/bin/bash

. $SCRIPTS_DIR/utils.sh


infoln "Deploying CC"

function packageChaincode() {
    local chaincode_name=$1

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

function deployChaincode() {
    # generate packages
    packageChaincode

    # # install chaincode
    # installChaincode 1
    # installChaincode 2

    # queryInstalled 1
    # queryInstalled 2

    # approveForMyOrg 1

    # ## check whether the chaincode definition is ready to be committed
    # ## expect org1 to have approved and org2 not to
    # checkCommitReadiness 1 "\"Org1MSP\": true" "\"Org2MSP\": false"
    # checkCommitReadiness 2 "\"Org1MSP\": true" "\"Org2MSP\": false"

    # approveForMyOrg 2

    # ## check whether the chaincode definition is ready to be committed
    # ## expect them both to have approved
    # checkCommitReadiness 1 "\"Org1MSP\": true" "\"Org2MSP\": true"
    # checkCommitReadiness 2 "\"Org1MSP\": true" "\"Org2MSP\": true"

    # # now that we know for sure both orgs have approved, commit the definition
    # commitChaincodeDefinition 1 2

    # queryCommitted 1
    # queryCommitted 2
}