{{- with datasource "values" -}}
export WHICH_ENV={{ .which_env }}
export WHICH_SITE={{ .which_site }}
export APPLICATION_NAME={{ .application_name }}
export HOSTNAME={{ .hostname }}
export HOME_DIR={{ .home_dir }}
export APP_SERVICE_ACCOUNT={{ .app_service_account }}
export APP_SERVICE_ACCOUNT_GROUP={{ .app_service_account_group }}
export KERBEROS_KEYTAB_PATH={{ .kerberos_keytab_path }}
export KERBEROS_TKT_PATH={{ .kerberos_tkt_path }}
export COMPONENT_NAME={{ .component_name }}
export COMPONENT_VERSION={{ .component_version }}
export DOWNLOAD_DEPLOY_DIR={{ .download_deploy_dir }}
export DOWNLOAD_COMPONENT_BINARY_DIR={{ .download_component_binary_dir }}
export DEPLOY_DIR={{ .deploy_dir }}
export COMPONENT_BINARY_DIR={{ .component_binary_dir }}
export COMPONENT_SCRIPTS_DIR={{ .component_scripts_dir }}
export COMPONENT_LOCAL_DATA_DIR={{ .component_local_data_dir }}
export APP_LOG_DIR={{ .app_log_dir }}
{{- end -}}