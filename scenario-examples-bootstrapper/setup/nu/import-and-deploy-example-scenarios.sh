#!/bin/bash -e

cd "$(dirname "$0")"

source ../../utils/lib.sh

if [ "$#" -ne 1 ]; then
    red_echo "ERROR: One parameter required: 1) scenario example folder path\n"
    exit 1
fi

SCENARIO_EXAMPLE_DIR_PATH=${1%/}

function import_and_deploy_scenario() {
  if [ "$#" -ne 2 ]; then
    red_echo "Error: Two parameters required: 1) scenario name, 2) example scenario file path\n"
    exit 11
  fi

  set -e

  local EXAMPLE_SCENARIO_NAME=$1
  local EXAMPLE_SCENARIO_FILE=$2

  ../../utils/nu/load-scenario-from-json-file.sh "$EXAMPLE_SCENARIO_NAME" "$EXAMPLE_SCENARIO_FILE"
  ../../utils/nu/deploy-scenario-and-wait-for-deployed-state.sh "$EXAMPLE_SCENARIO_NAME"

  if ! should_deploy_scenario "$SCENARIO_EXAMPLE_DIR_PATH"; then
    ../../utils/nu/cancel-scenario-and-wait-for-canceled-state.sh "$EXAMPLE_SCENARIO_NAME"
  fi
}

echo "Starting to import and deploy example scenarios..."

shopt -s nullglob

for ITEM in "$SCENARIO_EXAMPLE_DIR_PATH"/*; do
  if [ ! -f "$ITEM" ]; then
    continue
  fi

  if [[ ! "$ITEM" == *.json ]]; then
    red_echo "ERROR: Unrecognized file $ITEM. Required file with extension '.json' and content with Nu scenario JSON\n"
    exit 2
  fi

  EXAMPLE_SCENARIO_NAME="$(basename "$ITEM" ".json")"

  import_and_deploy_scenario "$EXAMPLE_SCENARIO_NAME" "$ITEM"
done

echo -e "Scenarios imported and deployed!\n"
