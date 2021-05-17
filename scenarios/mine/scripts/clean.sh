#!/bin/bash

. $PWD/scripts/init.sh
. $PWD/scripts/utils.sh
. $PWD/scripts/settings.sh


infoln "Cleaning the repository"

$PWD/scripts/stop.sh

# remove organizations
rm -rf $ORGANIZATION_OUTPUTS

# remove volumes
rm -rf volumes

# remove channels
rm -rf channels