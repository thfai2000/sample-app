#!/bin/bash
set -euo pipefail

COMPONENT_BINARY_DIR={{ getenv "COMPONENT_BINARY_DIR" }}
LINUX_SERVICE_NAME_PREFIX={{ getenv "LINUX_SERVICE_NAME_PREFIX" }}
LINUX_SERVICES_DIR=$COMPONENT_BINARY_DIR/linux-services


if [ -d "$LINUX_SERVICES_DIR" ]; then
    echo "# Loop through all files in the linux-services folder ($LINUX_SERVICES_DIR)"
    for file in $LINUX_SERVICES_DIR/*; do
        
        # set the name of the service
        SERVICE_NAME=$LINUX_SERVICE_NAME_PREFIX$(basename "$file")

        # get the status of the service
        SERVICE_STATUS=$(systemctl list-units --all | grep $SERVICE_NAME | awk '{print $3 }')
        echo "SERVICE_STATUS: $SERVICE_STATUS"

        if [ "$SERVICE_STATUS" == "active" ]; then
            echo "Service $SERVICE_NAME is running."
        else
            echo "Service $SERVICE_NAME is not running. Status: $SERVICE_STATUS"
            journalctl -u $SERVICE_NAME -n 100 --no-pager
        fi
    done
else
    echo "linux-services folder ($LINUX_SERVICES_DIR) does not exist"
    exit 1
fi