#!/bin/bash -e

cd "$(dirname "$0")"

source ../utils/lib.sh

magenta_echo "-------- SETUP STAGE is starting... -------\n"

shopt -s nullglob

for FOLDER in /scenario-examples/*; do
  if is_scenario_enabled "$FOLDER"; then
    echo -e "Starting to configure and run example scenarios from ${GREEN}$FOLDER${RESET} directory...\n\n"

    ./schema-registry/setup-schemas.sh "$FOLDER"
    ./kafka/setup-topics.sh "$FOLDER"
    ./flink/execute-flink-ddl-scripts.sh "$FOLDER"
    ./nu/customize-nu-configuration.sh "$FOLDER"
    ./nu/import-and-deploy-example-scenarios.sh "$FOLDER"
    
    echo -e "Scenarios from ${GREEN}$FOLDER${RESET} directory configured and running!\n\n"
  else
    echo "Skipping configuring and running example scenario from ${GREEN}$FOLDER${RESET} directory."
  fi
done

magenta_echo "-------- SETUP STAGE is finished! ---------\n\n"
