#!/bin/bash

cd "$(dirname "$0")"

source ../lib.sh
configure_error_handling

source /configs/nu-designer

if [ "$#" -lt 3 ]; then
  red_echo "ERROR: Three parameters required: 1) scenario name, 2) source name 3) endpoint name\n"
  exit 1
fi

if ! [ -v NU_DESIGNER_URL ] || [ -z "$NU_DESIGNER_URL" ]; then
  red_echo "ERROR: required variable NU_DESIGNER_URL not set or empty\n"
  exit 2
fi

if ! [ -v NU_DESIGNER_AUTH_HEADER ] || [ -z "$NU_DESIGNER_AUTH_HEADER" ]; then
  red_echo "ERROR: required variable NU_DESIGNER_AUTH_HEADER not set or empty\n"
  exit 3
fi

SCENARIO_NAME=$1
SOURCE_NAME=$2
ENDPOINT_NAME=$3

REQUEST_BODY=$(jq -n \
  --arg endpointName "$ENDPOINT_NAME" \
  --arg sourceName "$SOURCE_NAME" \
  '{
    actionName: "generate-endpoint",
    endpointName: $endpointName,
    nodeData: {
      id: $sourceName,
      ref: { typ: "webhook", parameters: [] },
      type: "Source"
    }
  }')

RESPONSE=$(curl -k -s -L -w "\n%{http_code}" \
  -H "Authorization: $NU_DESIGNER_AUTH_HEADER" \
  -X POST "${NU_DESIGNER_URL}/api/custom/nodes/$(urlencode "$SCENARIO_NAME")/actions" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_BODY"
)

HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)
RESPONSE_BODY=$(echo "$RESPONSE" | sed \$d)

if [ "$HTTP_STATUS" == "409" ]; then
  echo "Endpoint '$ENDPOINT_NAME' already exists."
elif [ "$HTTP_STATUS" != "201" ]; then
  red_echo "ERROR: Cannot create endpoint '$ENDPOINT_NAME'.\nHTTP status: $HTTP_STATUS, response body: $RESPONSE_BODY\n"
  exit 4
fi
