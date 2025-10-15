#!/bin/bash

cd "$(dirname "$0")"

source ../utils/lib.sh
configure_error_handling

magenta_echo "-------- SCENARIO RESOURCES SETUP STAGE is starting... -------\n"

shopt -s nullglob

for FOLDER in /scenario-examples/*; do
  if is_scenario_enabled "$FOLDER"; then
    echo -e "Starting to configure scenario resources from ${GREEN}$FOLDER${RESET} directory...\n\n"

    ./schema-registry/setup-schemas.sh "$FOLDER"
    ./kafka/setup-topics.sh "$FOLDER"
    ./flink/execute-flink-ddl-scripts.sh "$FOLDER"
    
    echo -e "Scenario resources from ${GREEN}$FOLDER${RESET} directory configured!\n\n"
  else
    echo "Skipping configuring from ${GREEN}$FOLDER${RESET} directory."
  fi
done

magenta_echo "-------- SCENARIO RESOURCES SETUP STAGE is finished! ---------\n\n"
