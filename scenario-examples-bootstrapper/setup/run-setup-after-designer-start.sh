#!/bin/bash

cd "$(dirname "$0")"

source ../utils/lib.sh
configure_error_handling

magenta_echo "-------- SCENARIOS SETUP STAGE is starting... -------\n"

shopt -s nullglob

for FOLDER in /scenario-examples/*; do
  if is_scenario_enabled "$FOLDER"; then
    echo -e "Starting to configure and run example scenario from ${GREEN}$FOLDER${RESET} directory...\n\n"

    json_files=("$FOLDER"/*.json)

    if [ ${#json_files[@]} -eq 0 ]; then
      red_echo "ERROR: No .json scenario files found in $FOLDER\n"
      exit 1
    elif [ ${#json_files[@]} -gt 1 ]; then
      red_echo "ERROR: Only one .json scenario file is allowed per example scenario folder. Found .json files:"
      for f in "${json_files[@]}"; do
        red_echo "  - $f"
      done
      exit 2
    fi

    SCENARIO_FILE_PATH="${json_files[0]}"
    SCENARIO_NAME="$(basename "$SCENARIO_FILE_PATH" ".json")"

    ./nu/create-http-endpoints.sh "$FOLDER" "$SCENARIO_NAME"
    ./nu/customize-nu-configuration.sh "$FOLDER"
    ./nu/import-and-deploy-example-scenario.sh "$FOLDER" "$SCENARIO_NAME" "$SCENARIO_FILE_PATH"
    
    echo -e "Scenarios from ${GREEN}$FOLDER${RESET} directory configured and running!\n\n"
  else
    echo "Skipping configuring and running example scenario from ${GREEN}$FOLDER${RESET} directory."
  fi
done

magenta_echo "-------- SCENARIOS SETUP STAGE is finished! ---------\n\n"
