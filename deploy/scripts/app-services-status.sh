#!/bin/bash

set -euo pipefail

if [ -d "$APP_BINARY_DIR" ]; then
    for dir in $APP_BINARY_DIR/*; do
        
        # set the path to the file
        FILE_PATH="$dir/scripts/services-status.sh"
        
        # check if the file exists
        if [[ -f "$FILE_PATH" &&  ! "$FILE_PATH" == *"@"* ]]; then
            bash $FILE_PATH
        fi
    done
else
    echo "App binary folder ($APP_BINARY_DIR) does not exist"
    exit 1
fi

