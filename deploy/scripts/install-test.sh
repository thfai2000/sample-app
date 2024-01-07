#!/bin/bash
set -euo pipefail

export DEPLOY_DIR=$1
export COMPONENT_BINARY_DIR=$2

echo "required arguments:"
echo "DEPLOY_DIR=$DEPLOY_DIR"
echo "COMPONENT_BINARY_DIR=$COMPONENT_BINARY_DIR"

export COMPONENT_NAME="COMPONENT_NAME"
export COMPONENT_VERSION="COMPONENT_VERSION"
export APPLICATION_NAME="ITWS.PMUCOL-APP"
export WHICH_ROLE="WHICH_ROLE"
export HOST_LABEL="HOST_LABEL"
export APP_SERVICE_ACCOUNT="APP_SERVICE_ACCOUNT"
export APP_SERVICE_ACCOUNT_GROUP="APP_SERVICE_ACCOUNT"
export KERBEROS_KEYTAB_PATH="KERBEROS_KEYTAB_PATH"
export KERBEROS_TKT_PATH="KERBEROS_TKT_PATH"
export HOME_DIR="HOME_DIR"
export COMPONENT_LOCAL_DATA_DIR="COMPONENT_LOCAL_DATA_DIR"
export DOWNLOAD_DEPLOY_DIR="DOWNLOAD_DEPLOY_DIR"
export DOWNLOAD_COMPONENT_BINARY_DIR="DOWNLOAD_COMPONENT_BINARY_DIR"
export COMPONENT_SCRIPTS_DIR="COMPONENT_SCRIPTS_DIR"
export COMPONENT_TEMPLATES_DIR="COMPONENT_TEMPLATES_DIR"
export APP_LOG_DIR="APP_LOG_DIR"
export WINDOW_SERVICE_NAME_PREFIX="WINDOW_SERVICE_NAME_PREFIX-"
export JAVA_HOME_DIR="JAVA_HOME_DIR"
export PRINT_ALL_RENDERED_TEMPLATES_FLAG="1"
export SSL_TRUST_STORE_DIR="SSL_TRUST_STORE_DIR"
export SSL_TRUST_STORE_PASSWORD="SSL_TRUST_STORE_PASSWORD"
export SSL_CERT_DIR="SSL_CERT_DIR"
export APPDYNAMIC_AGENT_JAR_FILEPATH="APPDYNAMIC_AGENT_JAR_FILEPATH"
export MONGODB_OPSMGR_PROJID="MONGODB_OPSMGR_PROJID"
export MONGODB_OPSMGR_CLUSTERID="MONGODB_OPSMGR_CLUSTERID"
export MONGODB_OPSMGR_PUBKEY="MONGODB_OPSMGR_PUBKEY"
export MONGODB_OPSMGR_PRIVKEY="MONGODB_OPSMGR_PRIVKEY"

VALUE_FOLDER="$DEPLOY_DIR/values"
echo "VALUE_FOLDER=$VALUE_FOLDER"

# Loop through files in the folder
for file in "$VALUE_FOLDER"/*.yaml "$VALUE_FOLDER"/*.yml; do
    if [ -f "$file" ]; then  # Check if it's a file
        filename=$(basename "$file")  # Extract the file name
        export WHICH_ENV=$(basename "$file" | cut -d. -f1)
        
        
        sites=("st" "hv")
        # Loop through the values
        for site in "${sites[@]}"; do
            # Execute command for each site values
            export WHICH_SITE=$site
            # Execute the script with the file name as an argument
            OUTPUT_FOLDER=/tmp/gomplate/$WHICH_ENV
            TEMPLATE_FOLDER=$COMPONENT_BINARY_DIR/templates
            VALUE_FILE=$VALUE_FOLDER/$filename
            echo 'Going to token replace'
            echo "WHICH_SITE=$WHICH_SITE"
            echo "TEMPLATE_FOLDER=$TEMPLATE_FOLDER"
            echo "VALUE_FILE=$VALUE_FILE"
            echo "OUTPUT_FOLDER= $OUTPUT_FOLDER"
            rm -rf $OUTPUT_FOLDER
            $DEPLOY_DIR/scripts/render-template.sh $VALUE_FILE $TEMPLATE_FOLDER $OUTPUT_FOLDER
            echo "token replace completed"
        done
    fi
done
