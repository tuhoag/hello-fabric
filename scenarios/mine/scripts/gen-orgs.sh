#!/bin/bash

. $PWD/scripts/init.sh
. $PWD/scripts/utils.sh

function generateNormalOrg() {
    infoln "Creating Org$1's Identities"
    configPath=$ORG_CONFIG_PATH/crypto-config-org$1.yaml
    infoln $configPath

    generateOrg $configPath $ORGANIZATION_OUTPUTS
}

function generateOrdererOrgs() {
    infoln "Creating Orderer Org's Identities"
    configPath=$ORG_CONFIG_PATH/crypto-config-orderer.yaml

    generateOrg $configPath $ORGANIZATION_OUTPUTS
}

function generateOrg() {
    configPath=$1
    outputPath=$2

    infoln "Config path: $configPath"
    infoln "Output path: $outputPath"

    set -x
    cryptogen generate --config=$configPath --output=$outputPath
    res=$?
    { set +x; } 2>/dev/null

    if [ $res -ne 0 ]; then
        fatalln "Failed to generate certificates..."
    fi
}



# get inputs
if [ $# -eq 0 ]; then
    # infoln "No arguments supplied"
    generateOrdererOrgs
else
    org=$1
    generateNormalOrg $org
fi