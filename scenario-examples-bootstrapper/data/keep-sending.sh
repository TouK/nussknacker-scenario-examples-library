#!/bin/bash -e

cd "$(dirname "$0")"

source ../utils/lib.sh

if is_data_generation_active; then 
  magenta_echo "-------- DATA GENERATION ACTIVATION STAGE is starting... ------\n"
  
  shopt -s nullglob
  
  for FOLDER in /scenario-examples/*; do   
    if is_scenario_enabled "$FOLDER"; then
      echo -e "Starting to send static and generated data for scenario from ${GREEN}$FOLDER${RESET} directory...\n\n"
  
      ./http/send-http-static-requests.sh "$FOLDER"
      ./kafka/send-kafka-static-messages.sh "$FOLDER"
      ./http/continuously-send-http-generated-requests.sh "$FOLDER"
      ./kafka/continuously-send-kafka-generated-messages.sh "$FOLDER"
  
      echo -e "Static data sent and generators from ${GREEN}$FOLDER${RESET} directory are runnning!\n\n"
    else
      echo -e "Skipping sending static and generated data for scenario from ${GREEN}$FOLDER${RESET} directory.\n"
    fi
  done
  
  magenta_echo "-------- DATA GENERATION ACTIVATION STAGE is finished! --------\n\n"
else
  magenta_echo "-------- DATA GENERATION IS DISABLED! ------\n"
fi
