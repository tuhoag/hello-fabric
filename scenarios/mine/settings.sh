#!/bin/bash

# environment variables
export PROJECT_DIR=$PWD
export SCRIPTS_DIR=$PROJECT_DIR/scripts
export FABRIC_BIN_PATH=$PROJECT_DIR/bin
export CONFIG_PATH=$PROJECT_DIR/config
export ORGANIZATION_OUTPUTS=$PROJECT_DIR/organizations
export ORG_CONFIG_PATH=$CONFIG_PATH
export CHANNEL_PATH=$PROJECT_DIR/channels
export DOCKER_COMPOSE_PATH=$PROJECT_DIR/docker/docker-compose.yml
export FABRIC_CFG_PATH=$CONFIG_PATH


export FABRIC_VERSION=2.2
export PROJECT_NAME=promark


export NETWORK_NAME=${PROJECT_NAME}_test
export LOGSPOUT_PORT=8000
export ADV_BASE_PORT=1050
export BUS_BASE_PORT=2050

export ORDERER_ADDRESS=0.0.0.0:7050
export ORDERER_HOSTNAME=orderer.$PROJECT_NAME.com
export ORDERER_CA=$ORGANIZATION_OUTPUTS/ordererOrganizations/$PROJECT_NAME.com/orderers/$ORDERER_HOSTNAME/msp/tlscacerts/tlsca.$PROJECT_NAME.com-cert.pem

export PATH=$FABRIC_BIN_PATH:$PATH