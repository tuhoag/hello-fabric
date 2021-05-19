#!/bin/bash

. $SCRIPTS_DIR/utils.sh


infoln "Deploying CC"


function packageChaincode() {
    local chaincode_name=$1
    local chaincode_package_name="$CHAINCODE_PACKAGE_PATH/${chaincode_name}.tar.gz"
    local chaincode_label="${chaincode_name}_1.0"

    infoln "Packaging chaincode $chaincode_name"

    infoln "Vendoring Go dependencies at $CHAINCODE_SRC_PATH"
    pushd $CHAINCODE_SRC_PATH
    GO111MODULE=on go mod vendor
    popd
    successln "Finished vendoring Go dependencies"

    # if [ ! -d $CC_PACKAGE_FOLDER_OUTPUT ]; then
    #     mkdir $CC_PACKAGE_FOLDER_OUTPUT
    # fi

    set -x
    peer lifecycle chaincode package $chaincode_package_name --path $CHAINCODE_PACKAGE_PATH --lang $CHAINCODE_LANGUAGE --label $chaincode_label >&log.txt
    res=$?
    { set +x; } 2>/dev/null

    cat log.txt
    verifyResult $res "Chaincode packaging has failed"
    successln "Chaincode is packaged"
}

packageChaincode $1

# function deployChaincode() {
#     # generate packages
#     packageChaincode

#     # # install chaincode
#     # installChaincode 1
#     # installChaincode 2

#     # queryInstalled 1
#     # queryInstalled 2

#     # approveForMyOrg 1

#     # ## check whether the chaincode definition is ready to be committed
#     # ## expect org1 to have approved and org2 not to
#     # checkCommitReadiness 1 "\"Org1MSP\": true" "\"Org2MSP\": false"
#     # checkCommitReadiness 2 "\"Org1MSP\": true" "\"Org2MSP\": false"

#     # approveForMyOrg 2

#     # ## check whether the chaincode definition is ready to be committed
#     # ## expect them both to have approved
#     # checkCommitReadiness 1 "\"Org1MSP\": true" "\"Org2MSP\": true"
#     # checkCommitReadiness 2 "\"Org1MSP\": true" "\"Org2MSP\": true"

#     # # now that we know for sure both orgs have approved, commit the definition
#     # commitChaincodeDefinition 1 2

#     # queryCommitted 1
#     # queryCommitted 2
# }