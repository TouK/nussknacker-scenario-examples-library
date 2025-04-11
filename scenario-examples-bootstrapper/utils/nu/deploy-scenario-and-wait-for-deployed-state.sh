#!/bin/bash -e

cd "$(dirname "$0")"

source ../lib.sh
source /configs/nu-designer

if [ "$#" -lt 1 ]; then
  red_echo "ERROR: One parameter required: 1) scenario name\n"
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
TIMEOUT_SECONDS=${2:-720}
WAIT_INTERVAL=5

function deploy_scenario() {
  if [ "$#" -ne 1 ]; then
      red_echo "ERROR: One parameter required: 1) scenario name\n"
      exit 11
  fi

  set -e

  local SCENARIO_NAME=$1

  local RESPONSE
  RESPONSE=$(curl -k -s -L -w "\n%{http_code}" \
    -H "Authorization: $NU_DESIGNER_AUTH_HEADER" \
    -X POST "${NU_DESIGNER_URL}/api/processManagement/deploy/$(urlencode "$SCENARIO_NAME")" \
    -H "Content-Type: application/json" \
    -d '{"comment":"Scenario is deployed."}'
  )

  local HTTP_STATUS
  HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)

  if [ "$HTTP_STATUS" != "200" ]; then
    local RESPONSE_BODY
    RESPONSE_BODY=$(echo "$RESPONSE" | sed \$d)
    red_echo "ERROR: Cannot run scenario $SCENARIO_NAME deployment.\nHTTP status: $HTTP_STATUS, response body: $RESPONSE_BODY\n"
    exit 12
  fi

  echo "Scenario $SCENARIO_NAME deployment started..."
}

function check_deployment_status() {
  if [ "$#" -ne 1 ]; then
    red_echo "ERROR: One parameter required: 1) scenario name\n"
    exit 21
  fi

  set -e

  local SCENARIO_NAME=$1

  local RESPONSE
  RESPONSE=$(curl -k -s -L -w "\n%{http_code}" \
    -H "Authorization: $NU_DESIGNER_AUTH_HEADER" \
    -X GET "${NU_DESIGNER_URL}/api/processes/$(urlencode "$SCENARIO_NAME")/status"
  )

  local HTTP_STATUS
  HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)
  local RESPONSE_BODY
  RESPONSE_BODY=$(echo "$RESPONSE" | sed \$d)

  if [ "$HTTP_STATUS" != "200" ]; then
    red_echo "ERROR: Cannot check scenario $SCENARIO_NAME deployment status.\nHTTP status: $HTTP_STATUS, response body: $RESPONSE_BODY\n"
    exit 22
  fi

  local SCENARIO_STATUS
  SCENARIO_STATUS=$(echo "$RESPONSE_BODY" | jq -r '.status.name')
  echo "$SCENARIO_STATUS"
}

echo "Deploying scenario '$SCENARIO_NAME'..."

START_TIME=$(date +%s)
END_TIME=$((START_TIME + TIMEOUT_SECONDS))

DEPLOYMENT_STATUS=""
while true; do
  DEPLOYMENT_STATUS=$(check_deployment_status "$SCENARIO_NAME")

  if [[ "$DEPLOYMENT_STATUS" != "DURING_DEPLOY" ]]; then
    break
  fi

  CURRENT_TIME=$(date +%s)
  if [ $CURRENT_TIME -gt $END_TIME ]; then
    red_echo "ERROR: Timeout for waiting for different than DURING_DEPLOY state of '$SCENARIO_NAME' deployment reached!\n"
    exit 3
  fi

  echo "'$SCENARIO_NAME' is busy. Deployment state is $DEPLOYMENT_STATUS. Checking again in $WAIT_INTERVAL seconds..."
  sleep $WAIT_INTERVAL
done

deploy_scenario "$SCENARIO_NAME"

DEPLOYMENT_STATUS=""
while true; do
  DEPLOYMENT_STATUS=$(check_deployment_status "$SCENARIO_NAME")

  if [[ "$DEPLOYMENT_STATUS" == "RUNNING" || "$DEPLOYMENT_STATUS" == "FINISHED" ]]; then
    break
  fi

  CURRENT_TIME=$(date +%s)
  if [ $CURRENT_TIME -gt $END_TIME ]; then
    red_echo "ERROR: Timeout for waiting for the RUNNING (or FINISHED) state of '$SCENARIO_NAME' deployment reached!\n"
    exit 4
  fi

  echo "Waiting to be deployed. '$SCENARIO_NAME' deployment state is $DEPLOYMENT_STATUS. Checking again in $WAIT_INTERVAL seconds..."
  sleep $WAIT_INTERVAL
done

echo "Scenario '$SCENARIO_NAME' is $DEPLOYMENT_STATUS!"
