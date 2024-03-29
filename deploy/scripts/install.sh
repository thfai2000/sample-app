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
"PRINT_ALL_RENDERED_TEMPLATES_FLAG"
"PRINT_BASH_COMMANDS_FLAG"
"DOWNLOAD_DEPLOY_DIR"
"DOWNLOAD_COMPONENT_BINARY_DIR"
"DEPLOY_DIR"
"COMPONENT_BINARY_DIR"
"COMPONENT_SCRIPTS_DIR"
"COMPONENT_TEMPLATES_DIR"
"COMPONENT_LOCAL_DATA_DIR"
"APP_LOG_DIR"
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

echo "Unzip files for checking"
UNZIPPED_COMPONENT_BINARY_DIR=$DOWNLOAD_COMPONENT_BINARY_DIR/unzipped 
mkdir -p $UNZIPPED_COMPONENT_BINARY_DIR

zip_files=$(find $DOWNLOAD_COMPONENT_BINARY_DIR -name "*.zip")
if [ -n "$zip_files" ]; then
  echo "Unzipping files..."
  find $DOWNLOAD_COMPONENT_BINARY_DIR -name "*.zip" -exec unzip {} -d $UNZIPPED_COMPONENT_BINARY_DIR/ \;
else
  echo "No zip files found."
fi

tar_files=$(find $DOWNLOAD_COMPONENT_BINARY_DIR -name "*.tar")
if [ -n "$tar_files" ]; then
  echo "Untarring files..."
  tar -zxvf $DOWNLOAD_COMPONENT_BINARY_DIR/*.tar -C $UNZIPPED_COMPONENT_BINARY_DIR/
else
  echo "No tar files found."
fi

gz_files=$(find $DOWNLOAD_COMPONENT_BINARY_DIR -name "*.tar.gz")
if [ -n "$gz_files" ]; then
  echo "Untarring gzipped files..."
  tar -zxvf $DOWNLOAD_COMPONENT_BINARY_DIR/*.tar.gz -C $UNZIPPED_COMPONENT_BINARY_DIR/
else
  echo "No gzipped tar files found."
fi


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

# Check the existence of the Value YAML of a specific environment
if [ ! -f "$DEPLOY_DIR/values/$WHICH_ENV.yaml" ]; then
    echo "ERROR: Value YAML for environment $WHICH_ENV does not exist."
    exit 1
fi


# Check the existence of specific scripts and files
if [ ! -f "$DEPLOY_DIR/scripts/render-template.sh" ] || [ ! -f "$DEPLOY_DIR/scripts/app-services-status.sh" ]; then
    echo "ERROR: One or more required scripts or files are missing."
    exit 1
fi

# Check the existence of specific scripts and files
if [ ! -f "$UNZIPPED_COMPONENT_BINARY_DIR/templates/scripts/start.sh" ] && [ ! -f "$UNZIPPED_COMPONENT_BINARY_DIR/scripts/start.sh" ]; then
    echo "ERROR: start.sh is missing."
    exit 1
fi

# Check the existence of specific scripts and files
if [ ! -f "$UNZIPPED_COMPONENT_BINARY_DIR/templates/scripts/stop.sh" ] && [ ! -f "$UNZIPPED_COMPONENT_BINARY_DIR/scripts/stop.sh" ]; then
    echo "ERROR: stop.sh is missing."
    exit 1
fi

# Check the existence of specific scripts and files
if [ ! -f "$UNZIPPED_COMPONENT_BINARY_DIR/templates/scripts/liveness-check.sh" ] && [ ! -f "$UNZIPPED_COMPONENT_BINARY_DIR/scripts/liveness-check.sh" ]; then
    echo "ERROR: liveness-check.sh is missing."
    exit 1
fi

# Check the existence of specific scripts and files
if [ ! -f "$UNZIPPED_COMPONENT_BINARY_DIR/templates/scripts/readiness-check.sh" ] && [ ! -f "$UNZIPPED_COMPONENT_BINARY_DIR/scripts/readiness-check.sh" ]; then
    echo "ERROR: readiness-check.sh is missing."
    exit 1
fi

echo "Find all templates files with UCD_SECRET and extract the tokens"
secret_tokens=$(grep -hRo 'UCD_SECRET_[[:alnum:]_]*' "$UNZIPPED_COMPONENT_BINARY_DIR/templates" | sort -u || true)

echo "# secret_tokens varable is: $secret_tokens"
# Generate the export statements
if [ -n "$secret_tokens" ]; then
    for token in $secret_tokens; do
      echo "checking $token..."
      if [ -z "${!token}" ]; then
        expected_ucd_name=$(echo $token | tr '[:upper:]' '[:lower:]')
        echo "$token environment variable is not set or empty. Please set the resource property $expected_ucd_name"
        exit 1
      fi
    done
else
    echo "# secret_tokens is empty."
fi

#Handling secret -start (Masking secret environment)
echo "Masking secret environment..."
set +x
for var in $(env | grep UCD_SECRET | awk -F '=' '{print $1}'); do
    new_var=$(echo $var | sed 's/UCD_SECRET/passed_UCD_SECRET/')
    export $new_var=${!var}
    export $var=****$var****
done
if [ "$PRINT_BASH_COMMANDS_FLAG" -eq "1" ]; then
  set -x
fi
#Handling secret -end (Masking secret environment)

# Create a local user for a template renderer
# useradd -m -s /bin/bash template_user

echo "Dry run of template rendering"

mkdir -p /tmp/gomplate/$WHICH_ENV/
rm -rf /tmp/gomplate/$WHICH_ENV/*
$DEPLOY_DIR/scripts/render-template.sh $DEPLOY_DIR/values/$WHICH_ENV.yaml $UNZIPPED_COMPONENT_BINARY_DIR/templates /tmp/gomplate/$WHICH_ENV/


if [ "$PRINT_ALL_RENDERED_TEMPLATES_FLAG" -eq "1" ]; then
    find /tmp/gomplate/$WHICH_ENV/ -type f | while read file
    do
        # Read file contents and replace newlines with "@@@@"
        # content=$(cat $file | tr '\n' '@@@@')
        # echo "Rendered Template [$file]:$content"
        echo "<<<<<<< File: $file - Start of Content >>>>>>>"
        cat "$file"
        echo "<<<<<<< File: $file - End of Content >>>>>>>"
    done
fi

#Handling secret -start (recover secret environment)
echo "Recovering secret environment..."
set +x
for var in $(env | grep passed_UCD_SECRET | awk -F '=' '{print $1}'); do
    new_var=$(echo $var | sed 's/passed_UCD_SECRET/UCD_SECRET/')
    export $new_var=${!var}
done
if [ "$PRINT_BASH_COMMANDS_FLAG" -eq "1" ]; then
  set -x
fi
#Handling secret -end  (recover secret environment)


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

echo "# Copy files from download directory to component directory"
cp -r $UNZIPPED_COMPONENT_BINARY_DIR/* $COMPONENT_BINARY_DIR/.


echo "# Real run of template rendering"
# Real run of template rendering
$DEPLOY_DIR/scripts/render-template.sh \
    $DEPLOY_DIR/values/$WHICH_ENV.yaml \
    $COMPONENT_TEMPLATES_DIR \
    $COMPONENT_BINARY_DIR/

echo "# Change file ownership and permissions"
chown -R $APP_SERVICE_ACCOUNT:$APP_SERVICE_ACCOUNT_GROUP $COMPONENT_BINARY_DIR $COMPONENT_SCRIPTS_DIR
chmod -R 754 $COMPONENT_BINARY_DIR $COMPONENT_SCRIPTS_DIR


echo "Copying files is completed. Going to enable any linux services."
exit 0
