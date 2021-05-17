#!/bin/bash

. $PWD/scripts/init.sh
. $PWD/scripts/utils.sh

function generateOrg() {
    org=$1
    outputPath=$2
    configPath=$ORG_CONFIG_PATH/crypto-config-$org.yaml

    infoln "Config path: $configPath"
    infoln "Output path: $outputPath"

    set -x
    cryptogen generate --config=$configPath --output=$outputPath
    res=$?
    { set +x; } 2>/dev/null

    if [ $res -ne 0 ]; then
        fatalln "Failed to generate certificates..."
    fi

    if [ $org != "orderer" ]; then
        generateCCP $org
    fi

}

function one_line_pem {
    echo "`awk 'NF {sub(/\\n/, ""); printf "%s\\\\\\\n",$0;}' $1`"
}

function yaml_ccp {
    local PP=$(one_line_pem $4)
    local CP=$(one_line_pem $5)
    sed -e "s/\${ORG}/$1/" \
        -e "s/\${P0PORT}/$2/" \
        -e "s/\${CAPORT}/$3/" \
        -e "s#\${PEERPEM}#$PP#" \
        -e "s#\${CAPEM}#$CP#" \
        -e "s/\${DOMAIN}/$6/" \
        ./config/ccp-template.yaml | sed -e $'s/\\\\n/\\\n          /g'
}

function generateCCP() {
    org=$1

    infoln "Generating CCP of ${org}"

    if [ $org = "adv1" ]; then
        P0PORT=7051
        CAPORT=7054
        PEERPEM=organizations/peerOrganizations/${org}.${PROJECT_NAME}.com/tlsca/tlsca.$org.${PROJECT_NAME}.com-cert.pem
        CAPEM=organizations/peerOrganizations/$org.${PROJECT_NAME}.com/ca/ca.$org.${PROJECT_NAME}.com-cert.pem
        DOMAIN=$PROJECT_NAME
        # infoln $PEERPEM
        # infoln $CAPEM
        # echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/org1.example.com/connection-org1.json
        echo "$(yaml_ccp $org $P0PORT $CAPORT $PEERPEM $CAPEM $DOMAIN)" > ./organizations/peerOrganizations/$org.${PROJECT_NAME}.com/connection-$org.yaml
    elif [ $org = "bus1" ]; then

        P0PORT=9051
        CAPORT=8054
        PEERPEM=organizations/peerOrganizations/$org.${PROJECT_NAME}.com/tlsca/tlsca.$org.${PROJECT_NAME}.com-cert.pem
        CAPEM=organizations/peerOrganizations/$org.${PROJECT_NAME}.com/ca/ca.$org.${PROJECT_NAME}.com-cert.pem
        DOMAIN=$PROJECT_NAME
        # echo "$(json_ccp $ORG $P0PORT $CAPORT $PEERPEM $CAPEM)" > organizations/peerOrganizations/$org.${PROJECT_NAME}.com/connection-org2.json
        echo "$(yaml_ccp $org $P0PORT $CAPORT $PEERPEM $CAPEM $DOMAIN)" > organizations/peerOrganizations/$org.${PROJECT_NAME}.com/connection-$org.yaml
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
    generateOrg $org $ORGANIZATION_OUTPUTS
fi
