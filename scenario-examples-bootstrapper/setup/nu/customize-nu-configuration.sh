#!/bin/bash -ex

cd "$(dirname "$0")"

source ../../utils/lib.sh

if [ "$#" -ne 1 ]; then
  red_echo "ERROR: One parameter required: 1) scenario example folder path\n"
  exit 1
fi

SCENARIO_EXAMPLE_DIR_PATH=${1%/}
CONFS_DIR=/opt/nussknacker/conf/additional
APP_CUSTOMIZATION_FILE_PATH="$CONFS_DIR/additional-configuration.conf"
ADDED_LINES=0

function customize_nu_configuration() {
  if [ "$#" -ne 2 ]; then
    red_echo "ERROR: Two parameters required: 1) configuration file path 2) example scenario id\n"
    exit 11
  fi

  set -e

  local EXAMPLE_SCENARIO_RELATED_CONFIGURAION_FILE_PATH=$1
  local EXAMPLE_SCENARIO_ID=$2
  local EXAMPLE_SCENARIO_RELATED_CONFIGURAION_FILE_NAME="${EXAMPLE_SCENARIO_ID}-$(basename "$EXAMPLE_SCENARIO_RELATED_CONFIGURAION_FILE_PATH")"

  echo -n "Including $EXAMPLE_SCENARIO_RELATED_CONFIGURAION_FILE_PATH configuration... "

  cp -f "$EXAMPLE_SCENARIO_RELATED_CONFIGURAION_FILE_PATH" "$CONFS_DIR/$EXAMPLE_SCENARIO_RELATED_CONFIGURAION_FILE_NAME"
  local INCLUDE_CONF_LINE="include \"$EXAMPLE_SCENARIO_RELATED_CONFIGURAION_FILE_NAME\""

  if ! grep -qxF "$INCLUDE_CONF_LINE" "$APP_CUSTOMIZATION_FILE_PATH"; then
    echo "$INCLUDE_CONF_LINE" >> "$APP_CUSTOMIZATION_FILE_PATH"
    ((ADDED_LINES++))
  fi
  echo "OK"
}

function cleanup_nu_configuration() {
  if [ $ADDED_LINES -gt 0 ]; then
    sed -i "$(( $(wc -l < "$APP_CUSTOMIZATION_FILE_PATH") - $ADDED_LINES + 1 )),\$d" "$APP_CUSTOMIZATION_FILE_PATH"
  fi
  rm -f "$CONFS_DIR"/"$(basename "$SCENARIO_EXAMPLE_DIR_PATH")"-*.conf
}

echo "Starting to customize Nu configuration..."

mkdir -p "$CONFS_DIR"
touch "$APP_CUSTOMIZATION_FILE_PATH"

shopt -s nullglob

for ITEM in "$SCENARIO_EXAMPLE_DIR_PATH/setup/nu-designer"/*; do
  if [ ! -f "$ITEM" ]; then
    continue
  fi

  if [[ ! "$ITEM" == *.conf ]]; then
    red_echo "ERROR: Unrecognized file $ITEM. Required file with extension '.conf' and content with HOCON Nu configuration\n"
    exit 2
  fi

  SCENARIO_EXAMPLE_ID=$(basename "$SCENARIO_EXAMPLE_DIR_PATH")
  customize_nu_configuration "$ITEM" "$SCENARIO_EXAMPLE_ID"
done

if ! ../../utils/nu/reload-configuration.sh; then
  RELOAD_EXIT_CODE=$?
  echo "Failed to reload configuration (exit code: $RELOAD_EXIT_CODE). Cleaning up..."
  cleanup_nu_configuration
  exit $RELOAD_EXIT_CODE
fi

echo -e "Configuration customized!\n"