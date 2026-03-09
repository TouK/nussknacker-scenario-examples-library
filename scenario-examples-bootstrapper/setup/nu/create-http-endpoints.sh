#!/bin/bash

cd "$(dirname "$0")"

source ../../utils/lib.sh
configure_error_handling

if [ "$#" -ne 2 ]; then
    red_echo "ERROR: Two parameters required: 1) scenario example folder path, 2) scenario name\n"
    exit 1
fi

SCENARIO_EXAMPLE_DIR_PATH=${1%/}
EXAMPLE_SCENARIO_NAME=$2

echo "Starting to create Nu HTTP endpoints..."

for ITEM in "$SCENARIO_EXAMPLE_DIR_PATH/setup/cloud-endpoints"/*; do
    if [ ! -f "$ITEM" ]; then
      continue
    fi

    if [[ ! "$ITEM" == *.json ]]; then
      red_echo "ERROR: Unrecognized file $ITEM. Required file with extension '.json' and content with list of records with 'endpointName' and 'source' fields\n"
      exit 2
    fi

    jq -c '.[]' "$ITEM" | while read -r record; do
        ENDPOINT_NAME=$(echo "$record" | jq -er '.endpointName') || {
          red_echo "ERROR: Missing 'endpointName' in $ITEM"
          exit 3
        }

        SOURCE_NAME=$(echo "$record" | jq -er '.sourceId') || {
          red_echo "ERROR: Missing 'source' in $ITEM"
          exit 4
        }

        ../../utils/nu/create-http-endpoint-idempotently.sh "$EXAMPLE_SCENARIO_NAME" "$SOURCE_NAME" "$ENDPOINT_NAME"
    done

done

echo -e "Endpoints created!\n"
