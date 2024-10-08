#!/bin/bash -e

cd "$(dirname "$0")"

source ../lib.sh

if [ "$#" -lt 2 ]; then
  red_echo "ERROR: Two parameters required: 1) scenario name, 2) scenario JSON\n"
  exit 1
fi

SCENARIO_NAME=$1
SCENARIO_JSON=$2
SCENARIO_JSON_FILE="/tmp/scenario-$SCENARIO_NAME.json"

echo "$SCENARIO_JSON" > "$SCENARIO_JSON_FILE"
trap 'rm "$SCENARIO_JSON_FILE"' EXIT

./load-scenario-from-json-file.sh "$SCENARIO_NAME" "$SCENARIO_JSON_FILE"
