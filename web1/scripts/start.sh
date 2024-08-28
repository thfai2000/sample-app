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

        sudo systemctl start $SERVICE_NAME
        echo "started service $SERVICE_NAME"
    done
else
    echo "linux-services folder ($LINUX_SERVICES_DIR) does not exist"
    exit 1
fi

