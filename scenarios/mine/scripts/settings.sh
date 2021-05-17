#!/bin/bash

# environment variables
FABRIC_BIN_PATH=$PWD/bin
CONFIG_PATH=$PWD/config
ORG_CONFIG_PATH=$CONFIG_PATH
ORGANIZATION_OUTPUTS=$PWD/organizations
CHANNEL_PATH=$PWD/channels
DOCKER_COMPOSE_PATH=$PWD/docker/docker-compose.yml
FABRIC_VERSION=2.2
PROJECT_NAME=promark
ORDERER_CA=$ORGANIZATION_OUTPUTS/ordererOrganizations/$PROJECT_NAME.com/orderers/orderer.$PROJECT_NAME.com/msp/tlscacerts/tlsca.$PROJECT_NAME.com-cert.pem
export FABRIC_CFG_PATH=$CONFIG_PATH