#!/bin/bash

cd "$(dirname "$0")"

source ../lib.sh
configure_error_handling

source /configs/nu-designer

if [ "$#" -lt 2 ]; then
  red_echo "ERROR: Two parameters required: 1) scenario name, 2) scenario file path\n" >&2
  exit 1
fi

if ! [ -v NU_DESIGNER_URL ] || [ -z "$NU_DESIGNER_URL" ]; then
  red_echo "ERROR: required variable NU_DESIGNER_URL not set or empty\n" >&2
  exit 2
fi

if ! [ -v NU_DESIGNER_AUTH_HEADER ] || [ -z "$NU_DESIGNER_AUTH_HEADER" ]; then
  red_echo "ERROR: required variable NU_DESIGNER_AUTH_HEADER not set or empty\n" >&2
  exit 3
fi

SCENARIO_NAME=$1
SCENARIO_FILE_PATH=$2
CATEGORY=${3:-"Default"}

if [ ! -f "$SCENARIO_FILE_PATH" ]; then
  red_echo "ERROR: Cannot find file $SCENARIO_FILE_PATH with scenario\n" >&2
  exit 4
fi

function create_empty_scenario() {
  if [ "$#" -ne 5 ]; then
    red_echo "ERROR: Five parameters required: 1) scenario name, 2) processing mode, 3) category, 4) engine 5) isFragment\n" >&2
    exit 11
  fi

  set -e

  local SCENARIO_NAME=$1
  local PROCESSING_MODE=$2
  local CATEGORY=$3
  local ENGINE=$4
  local IS_FRAGMENT=$5

  local REQUEST_BODY="{
    \"name\": \"$SCENARIO_NAME\",
    \"processingMode\": \"$PROCESSING_MODE\",
    \"category\": \"$CATEGORY\",
    \"engineSetupName\": \"$ENGINE\",
    \"isFragment\": $IS_FRAGMENT
  }"

  local RESPONSE
  RESPONSE=$(curl -k -s -L -w "\n%{http_code}" \
    -H "Authorization: $NU_DESIGNER_AUTH_HEADER" \
    -X POST "${NU_DESIGNER_URL}/api/processes" \
    -H "Content-Type: application/json" -d "$REQUEST_BODY"
  )

  local HTTP_STATUS
  HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)

  if [ "$HTTP_STATUS" == "400" ]; then
    local RESPONSE_BODY
    RESPONSE_BODY=$(echo "$RESPONSE" | sed \$d)
    
    if [[ "$RESPONSE_BODY" == *"already exists"* ]]; then
      echo "Scenario '$SCENARIO_NAME' already exists." >&2
      return 0
    else
      red_echo "ERROR: Cannot create empty scenario '$SCENARIO_NAME'.\nHTTP status: $HTTP_STATUS, response body: $RESPONSE_BODY\n" >&2
      exit 12
    fi
  elif [ "$HTTP_STATUS" != "201" ]; then
    local RESPONSE_BODY
    RESPONSE_BODY=$(echo "$RESPONSE" | sed \$d)
    red_echo "ERROR: Cannot create empty scenario '$SCENARIO_NAME'.\nHTTP status: $HTTP_STATUS, response body: $RESPONSE_BODY\n" >&2
    exit 13
  fi

  echo "Empty scenario '$SCENARIO_NAME' created successfully."
}

function import_scenario_from_file() {
  if [ "$#" -ne 2 ]; then
    red_echo "ERROR: Two parameters required: 1) scenario name, 2) scenario file path\n" >&2
    exit 21
  fi

  set -e

  local SCENARIO_NAME=$1
  local SCENARIO_FILE=$2

  local RESPONSE
  RESPONSE=$(curl -k -s -L -w "\n%{http_code}" \
    -H "Authorization: $NU_DESIGNER_AUTH_HEADER" \
    -X POST "${NU_DESIGNER_URL}/api/processes/import/$(urlencode "$SCENARIO_NAME")" \
    -F "process=@$SCENARIO_FILE"
  )

  # Check response body and status code
  local HTTP_STATUS
  HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)

  local RESPONSE_BODY
  RESPONSE_BODY=$(echo "$RESPONSE" | sed \$d)

  if [ "$HTTP_STATUS" == "200" ]; then
    local SCENARIO_GRAPH
    SCENARIO_GRAPH=$(echo "$RESPONSE_BODY" | jq '.scenarioGraph')
    echo "$SCENARIO_GRAPH"
  else
    red_echo "ERROR: Cannot import scenario '$SCENARIO_NAME'.\nHTTP status: $HTTP_STATUS, response body: $RESPONSE_BODY\n" >&2
    exit 22
  fi
}

function save_scenario() {
  if [ "$#" -ne 2 ]; then
    red_echo "ERROR: Two parameters required: 1) scenario name, 2) scenario graph JSON representation\n" >&2
    exit 31
  fi

  set -e

  local SCENARIO_NAME=$1
  local SCENARIO_GRAPH_JSON=$2

  local REQUEST_BODY="{
    \"scenarioGraph\": $SCENARIO_GRAPH_JSON,
    \"comment\": \"\"
  }"

  local RESPONSE
  RESPONSE=$(curl -k -s -L -w "\n%{http_code}" \
    -H "Authorization: $NU_DESIGNER_AUTH_HEADER" \
    -X PUT "${NU_DESIGNER_URL}/api/processes/$(urlencode "$SCENARIO_NAME")" \
    -H "Content-Type: application/json" -d "$REQUEST_BODY"
  )

  local HTTP_STATUS
  HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)

  local RESPONSE_BODY
  RESPONSE_BODY=$(echo "$RESPONSE" | sed \$d)
  if [ "$HTTP_STATUS" != "200" ]; then
    red_echo "ERROR: Cannot save scenario '$SCENARIO_NAME'.\nHTTP status: $HTTP_STATUS, response body: $RESPONSE_BODY\n" >&2
    exit 32
  fi

  local NEW_SCENARIO_VERSION
  NEW_SCENARIO_VERSION=$(echo "$RESPONSE_BODY" | jq '.newVersion')

  echo "$NEW_SCENARIO_VERSION"
}

SCENARIO_FILE_NAME="${SCENARIO_FILE_PATH%.*}"
META_DATA_TYPE=$(jq -r .metaData.additionalFields.metaDataType < "$SCENARIO_FILE_PATH")
case "$SCENARIO_FILE_NAME" in
  *streaming)
    echo "Assuming that scenario is a Streaming scenario..." >&2
    ENGINE="Flink"
    PROCESSING_MODE="Unbounded-Stream"
    ;;
  *request-response)
    echo "Assuming that scenario is a Request-Response scenario..." >&2
    ENGINE="Lite Embedded"
    PROCESSING_MODE="Request-Response"
    ;;
  *batch)
    echo "Assuming that scenario is a Batch scenario..." >&2
    ENGINE="Flink"
    PROCESSING_MODE="Bounded-Stream"
    ;;
  *)
    case "$META_DATA_TYPE" in
      "StreamMetaData")
        ENGINE="Flink"
        PROCESSING_MODE="Unbounded-Stream"
        ;;
      "FragmentSpecificData")
        ENGINE="Flink"
        PROCESSING_MODE="Unbounded-Stream"
        ;;
      "LiteStreamMetaData")
        ENGINE="Lite Embedded"
        PROCESSING_MODE="Unbounded-Stream"
        ;;
      "RequestResponseMetaData")
        ENGINE="Lite Embedded"
        PROCESSING_MODE="Request-Response"
        ;;
      *)
        red_echo "ERROR: Cannot import scenario with metadata type: $META_DATA_TYPE\n" >&2
        exit 4
        ;;
    esac
    echo "Read scenario type from metadata ($META_DATA_TYPE): $ENGINE / $PROCESSING_MODE" >&2
    ;;
esac

case "$META_DATA_TYPE" in
  "FragmentSpecificData")
    IS_FRAGMENT=true
    ;;
  *)
    IS_FRAGMENT=false
    ;;
esac

create_empty_scenario "$SCENARIO_NAME" "$PROCESSING_MODE" "$CATEGORY" "$ENGINE" "$IS_FRAGMENT"
SCENARIO_GRAPH=$(import_scenario_from_file "$SCENARIO_NAME" "$SCENARIO_FILE_PATH")
NEW_SCENARIO_VERSION=$(save_scenario "$SCENARIO_NAME" "$SCENARIO_GRAPH")

echo "$IS_FRAGMENT" "$NEW_SCENARIO_VERSION"
