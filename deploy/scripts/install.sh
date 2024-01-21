#!/bin/bash
set -euo pipefail

# VERY IMPORTANT. DON't KEEP HISTORY...environment variable may contain secret
set +o history

# Step 1: Check necessary environment variables
env_vars=(
"WHICH_ENV"
"WHICH_SITE"
"APPLICATION_NAME"
"HOSTNAME"
"HOME_DIR"
"APP_SERVICE_ACCOUNT"
"APP_SERVICE_ACCOUNT_GROUP"
"KERBEROS_KEYTAB_PATH"
"KERBEROS_TKT_PATH"
"COMPONENT_NAME"
"COMPONENT_VERSION"
"PRINT_BASH_COMMANDS_FLAG"
"DOWNLOAD_DEPLOY_DIR"
"DOWNLOAD_COMPONENT_BINARY_DIR"
"COMPONENT_BINARY_DIR"
"COMPONENT_SCRIPTS_DIR"
"COMPONENT_LOCAL_DATA_DIR"
"APP_LOG_DIR"
"VALUE_FILE_PATH"
)

for env_var in "${env_vars[@]}"; do
  echo "checked $env_var"
  if [ -z "${!env_var}" ]; then
    expected_ucd_name=$(echo $env_var | tr '[:upper:]' '[:lower:]')
    echo "$env_var environment variable is not set or empty. Please set the resource property $expected_ucd_name"
    exit 1
  fi
done

# loop through all environment variables
for var in $(compgen -e)
do
    # check if the variable ends with "_DIR"
    if [[ "$var" == *_DIR ]]
    then
        # get the value of the variable
        dir="${!var}"
        # check if the value ends with "/"
        if [[ "${dir: -1}" == "/" || "${dir: -1}" == '\' ]]
        then
            echo "ERROR: Variable $var ends with a slash."
            echo "Value: $dir"
            exit 1
        fi
        # check if it is necessary
        if [[ " ${env_vars[*]} " == *" $var "* ]]; then
            # Check the existence of required directories and file permissions
            mkdir -p "$dir"
            if [ ! -d "$dir" ]; then
                echo "ERROR: $var=$dir is not a directory."
                exit 1
            fi

            chmod -R 754 "$dir"
            if [ "$(stat -c %a "$dir")" != "754" ]; then
                echo "ERROR: $dir does not have the correct file permissions."
                exit 1
            fi
        fi
    fi
done


# Check the existence of service accounts
if [ ! "$(id -u $APP_SERVICE_ACCOUNT 2>/dev/null)" ]; then
    echo "ERROR: Service account $APP_SERVICE_ACCOUNT does not exist."
    exit 1
fi
# Check if the user belongs to the group
if id -nG "$APP_SERVICE_ACCOUNT" | grep -qw "$APP_SERVICE_ACCOUNT_GROUP"; then
    echo "User $APP_SERVICE_ACCOUNT belongs to group $APP_SERVICE_ACCOUNT_GROUP"
else
    echo "ERROR: User $APP_SERVICE_ACCOUNT does not belong to group $APP_SERVICE_ACCOUNT_GROUP"
    exit 1
fi

echo "# Change file ownership and permissions"
chown -R $APP_SERVICE_ACCOUNT:$APP_SERVICE_ACCOUNT_GROUP $UNZIPPED_COMPONENT_BINARY_DIR
chmod -R 754 $UNZIPPED_COMPONENT_BINARY_DIR

# Check the existence of specific scripts and files
if [ ! -f "$DOWNLOAD_DEPLOY_DIR/scripts/render-template.sh" ] || [ ! -f "$DOWNLOAD_DEPLOY_DIR/scripts/app-services-status.sh" ]; then
    echo "ERROR: One or more required scripts or files are missing."
    exit 1
fi

# Check the existence of specific scripts and files
if [ ! -f "$UNZIPPED_COMPONENT_BINARY_DIR/scripts/start.sh" ]; then
    echo "ERROR: start.sh is missing."
    exit 1
fi

# Check the existence of specific scripts and files
if [ ! -f "$UNZIPPED_COMPONENT_BINARY_DIR/scripts/stop.sh" ]; then
    echo "ERROR: stop.sh is missing."
    exit 1
fi

# Check the existence of specific scripts and files
if [ ! -f "$UNZIPPED_COMPONENT_BINARY_DIR/scripts/liveness-check.sh" ]; then
    echo "ERROR: liveness-check.sh is missing."
    exit 1
fi

# Check the existence of specific scripts and files
if [ ! -f "$UNZIPPED_COMPONENT_BINARY_DIR/scripts/readiness-check.sh" ]; then
    echo "ERROR: readiness-check.sh is missing."
    exit 1
fi

echo "# Check the existence of files and remove the files and uninstall the app if necessary"
if [ -d "$COMPONENT_BINARY_DIR" ] && [ "$(ls -A $COMPONENT_BINARY_DIR)" ]; then

    echo "clean $COMPONENT_BINARY_DIR"
    mkdir -p $COMPONENT_BINARY_DIR@previous_version
    rm -rf $COMPONENT_BINARY_DIR@previous_version/*
    mv $COMPONENT_BINARY_DIR/* $COMPONENT_BINARY_DIR@previous_version/.
fi

# source before-install.sh
if [ -f "$UNZIPPED_COMPONENT_BINARY_DIR/scripts/before-install.sh" ]; then
    echo "Executing before-install.sh"
    source $UNZIPPED_COMPONENT_BINARY_DIR/scripts/before-install.sh
else
    echo "# Not found before-install.sh. Skipped."
fi

echo "# Real run of template rendering"
# Real run of template rendering
$DOWNLOAD_DEPLOY_DIR/scripts/render-template.sh \
    $VALUE_FILE_PATH \
    $UNZIPPED_COMPONENT_BINARY_DIR \
    $COMPONENT_BINARY_DIR/

echo "# Change file ownership and permissions"
chown -R $APP_SERVICE_ACCOUNT:$APP_SERVICE_ACCOUNT_GROUP $COMPONENT_BINARY_DIR $COMPONENT_SCRIPTS_DIR
chmod -R 754 $COMPONENT_BINARY_DIR $COMPONENT_SCRIPTS_DIR


echo "Copying files is completed. Going to enable any linux services."
exit 0
