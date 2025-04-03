#!/bin/bash -ex

cd "$(dirname "$0")"

source ../lib.sh
source /configs/nu-designer

if ! [ -v NU_DESIGNER_URL ] || [ -z "$NU_DESIGNER_URL" ]; then
  red_echo "ERROR: required variable NU_DESIGNER_URL not set or empty\n"
  exit 1
fi

if ! [ -v NU_DESIGNER_AUTH_HEADER ] || [ -z "$NU_DESIGNER_AUTH_HEADER" ]; then
  red_echo "ERROR: required variable NU_DESIGNER_AUTH_HEADER not set or empty\n"
  exit 2
fi

function reload_configuration() {
  set -e

  local RESPONSE
  RESPONSE=$(curl -k -s -L -w "\n%{http_code}" \
    -H "Authorization: $NU_DESIGNER_AUTH_HEADER" \
    -X POST "${NU_DESIGNER_URL}/api/app/model/reload"
  )

  local HTTP_STATUS
  HTTP_STATUS=$(echo "$RESPONSE" | tail -n 1)
  local RESPONSE_BODY
  RESPONSE_BODY=$(echo "$RESPONSE" | sed \$d)

  if [ "$HTTP_STATUS" != "204" ]; then
    red_echo "ERROR: Cannot reload Nu configuration.\nHTTP status: $HTTP_STATUS, response body: $RESPONSE_BODY\n"
    exit 22
  fi
}

echo -n "Reloading Nu configuration... "
reload_configuration
echo "OK"
