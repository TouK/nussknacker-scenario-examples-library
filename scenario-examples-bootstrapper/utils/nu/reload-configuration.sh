#!/bin/bash -e

cd "$(dirname "$0")"

source ../lib.sh

if ! [ -v NU_DESIGNER_URL ] || [ -z "$NU_DESIGNER_URL" ]; then
  red_echo "ERROR: required variable NU_DESIGNER_URL not set or empty\n"
  exit 1
fi

if ! [ -v NU_DESIGNER_USER ] || [ -z "$NU_DESIGNER_USER" ]; then
  red_echo "ERROR: required variable NU_DESIGNER_USER not set or empty\n"
  exit 2
fi

if ! [ -v NU_DESIGNER_PASSWORD ] || [ -z "$NU_DESIGNER_PASSWORD" ]; then
  red_echo "ERROR: required variable NU_DESIGNER_PASSWORD not set or empty\n"
  exit 3
fi

function reload_configuration() {
  set -e

  local RESPONSE
  RESPONSE=$(curl -k -s -L -w "\n%{http_code}" -u "$NU_DESIGNER_USER:$NU_DESIGNER_PASSWORD" \
    -X POST "${NU_DESIGNER_URL}/api/app/processingtype/reload"
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
