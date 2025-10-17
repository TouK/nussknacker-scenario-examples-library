#!/bin/bash

cd "$(dirname "$0")"

source ../../utils/lib.sh
configure_error_handling

if [ "$#" -ne 3 ]; then
    red_echo "ERROR: Three parameters required: 1) scenario example folder path, 2) scenario name, 3) scenario file path\n"
    exit 1
fi

SCENARIO_EXAMPLE_DIR_PATH=${1%/}
EXAMPLE_SCENARIO_NAME=$2
EXAMPLE_SCENARIO_FILE=$3

echo "Starting to import and deploy example scenario..."

LOAD_RESULT=$(../../utils/nu/load-scenario-from-json-file.sh "$EXAMPLE_SCENARIO_NAME" "$EXAMPLE_SCENARIO_FILE")
read -r IS_FRAGMENT NEW_SCENARIO_VERSION <<< "$LOAD_RESULT"

if [ "$IS_FRAGMENT" == "true" ]; then
  echo -e "Fragment imported!\n"
else
  ../../utils/nu/deploy-scenario-and-wait-for-deployed-state.sh "$EXAMPLE_SCENARIO_NAME" "$NEW_SCENARIO_VERSION"

  if ! should_deploy_scenario "$SCENARIO_EXAMPLE_DIR_PATH"; then
    ../../utils/nu/cancel-scenario-and-wait-for-canceled-state.sh "$EXAMPLE_SCENARIO_NAME"
  fi

  echo -e "Scenario imported and deployed!\n"
fi