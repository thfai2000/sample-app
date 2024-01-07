#!/bin/bash

set -euo pipefail

LINUX_SERVICES_DIR=$COMPONENT_BINARY_DIR/linux-services
OLD_LINUX_SERVICES_DIR=$COMPONENT_BINARY_DIR@previous_version/linux-services

# uninstall previous linux services
# remove previous linux services files
if [ -d "$OLD_LINUX_SERVICES_DIR" ]; then
    echo "# Loop through all files in the linux-services folder ($OLD_LINUX_SERVICES_DIR)"
    for file in $OLD_LINUX_SERVICES_DIR/*; do
        SERVICE_NAME=$LINUX_SERVICE_NAME_PREFIX$(basename "$file")
        echo "Going to disable $SERVICE_NAME"
        OLD_PATH=/etc/systemd/system/$SERVICE_NAME
        sudo systemctl daemon-reload
        sudo systemctl disable $SERVICE_NAME
        sudo rm $OLD_PATH
        sudo systemctl reset-failed
        echo "disabled service $SERVICE_NAME"
    done
else
    echo "linux-services folder ($OLD_LINUX_SERVICES_DIR) does not exist"
fi

# Check if the folder exists
if [ -d "$LINUX_SERVICES_DIR" ]; then
    echo "# Loop through all files in the linux-services folder ($LINUX_SERVICES_DIR)"
    for file in $LINUX_SERVICES_DIR/*; do
        SERVICE_NAME=$LINUX_SERVICE_NAME_PREFIX$(basename "$file")
        echo "Going to enable $SERVICE_NAME"
        NEW_PATH=/etc/systemd/system/$SERVICE_NAME
        sudo cp $file $NEW_PATH
        sudo systemctl daemon-reload
        sudo systemctl enable $SERVICE_NAME
        echo "enabled service $NEW_PATH"
    done
else
    echo "linux-services folder ($LINUX_SERVICES_DIR) does not exist"
fi