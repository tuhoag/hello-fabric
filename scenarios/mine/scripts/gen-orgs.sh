#!/bin/bash

. $PWD/scripts/init.sh
. $PWD/scripts/utils.sh

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

# check if cryptogen is accessible
set -x
which cryptogen
{ set +x; } 2>/dev/null
if [ "$?" -ne 0 ]; then
    fatalln "cryptogen tool not found."
fi

# get inputs
if [ $# -eq 0 ]; then
    errorln "No arguments supplied"
    # generateOrdererOrgs
else
    org=$1
    configPath=$ORG_CONFIG_PATH/crypto-config-$org.yaml
    generateOrg $configPath $ORGANIZATION_OUTPUTS
fi
