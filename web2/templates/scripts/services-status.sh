#!/bin/bash
set -euo pipefail

APPLICATION_NAME={{ getenv "APPLICATION_NAME" }}
COMPONENT_NAME={{ getenv "COMPONENT_NAME" }}
COMPONENT_VERSION={{ getenv "COMPONENT_VERSION" }}
COMPONENT_BINARY_DIR={{ getenv "COMPONENT_BINARY_DIR" }}
COMPONENT_DEPLOYMENT_TIME="{{ (time.Now).Format time.RFC822 }}"
WHICH_ENV={{ getenv "WHICH_ENV" }}
HOSTNAME=$(hostname)
HOST_LABEL={{ getenv "HOST_LABEL" }}
LINUX_SERVICES_DIR=$COMPONENT_BINARY_DIR/linux-services
LINUX_SERVICE_NAME_PREFIX={{ getenv "LINUX_SERVICE_NAME_PREFIX" }}

if [ -d "$LINUX_SERVICES_DIR" ]; then

    headers=(
    "Environment Name"
    "Hostname"
    "Host Label"
    "Application Name"
    "Component Name"
    "Component Artifact Version"
    "Component Deployment Time"
    "Service Name"
    "Service Status"
    )
    echo -e "$(IFS=$'\t'; echo "${headers[*]}")"
    for file in $LINUX_SERVICES_DIR/*; do

        # set the name of the service
        SERVICE_NAME=$LINUX_SERVICE_NAME_PREFIX$(basename "$file")

        # get the status of the service
        SERVICE_STATUS=$(systemctl status $SERVICE_NAME | grep 'Active:' | awk '{print $2 " " $3}' || true)

        # It prints out all the status of the app services with Tab as delimiter
        # For example 1:
        # dit1 WINODPSAPPST01 core pmu.odps accumulator 1.0.xxx 2023-06-05 11:56:59 active (running)
        # dit1 WINODPSAPPST01 core pmu.odps latest1.0.xxx 2023-06-05 11:56:59 stopped

        echo "$WHICH_ENV $HOSTNAME $HOST_LABEL $APPLICATION_NAME $COMPONENT_NAME $COMPONENT_VERSION $COMPONENT_DEPLOYMENT_TIME $SERVICE_NAME $SERVICE_STATUS"
    done
else
    echo "linux-services folder ($LINUX_SERVICES_DIR) does not exist"
    exit 1
fi