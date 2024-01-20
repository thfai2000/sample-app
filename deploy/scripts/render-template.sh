#!/bin/bash
set -euo pipefail

VALUE_FILE=$1
TEMPLATE_DIR=$2
OUTPUT_DIR=$3

echo "VALUE_FILE=$VALUE_FILE"
echo "TEMPLATE_DIR=$TEMPLATE_DIR"
echo "OUTPUT_DIR=$OUTPUT_DIR"

chmod 755 $(dirname "$0")/gomplate
$(dirname "$0")/gomplate \
--input-dir=$TEMPLATE_DIR \
--output-dir=$OUTPUT_DIR \
--datasource values=$VALUE_FILE \
--left-delim "{{" \
--right-delim "}}"