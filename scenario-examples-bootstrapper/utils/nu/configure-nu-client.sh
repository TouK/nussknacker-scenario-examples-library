#!/bin/bash -e

cd "$(dirname "$0")"

source ../lib.sh

NU_DESIGNER_CONFIG_FILE="/configs/nu-designer"
rm -f $NU_DESIGNER_CONFIG_FILE
touch $NU_DESIGNER_CONFIG_FILE

if [ -v NU_DESIGNER_ADDRESS ] && ! [ -v NU_DESIGNER_URL ]; then
  orange_echo "WARN: Nu Designer address is provided but URL is not set, setting it to ${NU_DESIGNER_ADDRESS}"
  echo "NU_DESIGNER_URL=\"http://${NU_DESIGNER_ADDRESS}\"" >> $NU_DESIGNER_CONFIG_FILE
fi

if ! [ -v NU_DESIGNER_AUTH_MODE ] || [ -z "$NU_DESIGNER_AUTH_MODE" ]; then
  NU_DESIGNER_AUTH_MODE="BASIC_AUTH"
fi

case "$NU_DESIGNER_AUTH_MODE" in
  "BASIC_AUTH")
    if [ ! -v NU_DESIGNER_USER ] || [ -z "$NU_DESIGNER_USER" ]; then
      NU_DESIGNER_USER="admin"
      echo "NU_DESIGNER_USER not set or empty, using default: admin"
    fi

    if [ ! -v NU_DESIGNER_PASSWORD ] || [ -z "$NU_DESIGNER_PASSWORD" ]; then
      NU_DESIGNER_PASSWORD="admin"
      echo "NU_DESIGNER_PASSWORD not set or empty, using default: admin"
    fi
    
    BASIC_AUTH=$(echo -n "$NU_DESIGNER_USER:$NU_DESIGNER_PASSWORD" | base64)
    echo "NU_DESIGNER_AUTH_HEADER=\"Basic $BASIC_AUTH\"" >> $NU_DESIGNER_CONFIG_FILE
    ;;
  "AUTH0") 
    if ! [ -v NU_DESIGNER_OAUTH_M2M_TOKEN_API_URL ] || [ -z "$NU_DESIGNER_OAUTH_M2M_TOKEN_API_URL" ]; then
      red_echo "ERROR: required variable NU_DESIGNER_OAUTH_M2M_TOKEN_API_URL not set or empty\n"
      exit 1
    fi
    if ! [ -v NU_DESIGNER_OAUTH_CLIENT_ID ] || [ -z "$NU_DESIGNER_OAUTH_CLIENT_ID" ]; then
      red_echo "ERROR: required variable NU_DESIGNER_OAUTH_CLIENT_ID not set or empty\n"
      exit 2
    fi
    if ! [ -v NU_DESIGNER_OAUTH_CLIENT_SECRET ] || [ -z "$NU_DESIGNER_OAUTH_CLIENT_SECRET" ]; then
      red_echo "ERROR: required variable NU_DESIGNER_OAUTH_CLIENT_SECRET not set or empty\n"
      exit 3
    fi

    ACCESS_TOKEN=$(curl --request POST \
      --url "$NU_DESIGNER_OAUTH_M2M_TOKEN_API_URL/api/oauth/token" \
      --header 'content-type: application/x-www-form-urlencoded' \
      --data grant_type=client_credentials \
      --data client_id="$NU_DESIGNER_OAUTH_CLIENT_ID" \
      --data client_secret="$NU_DESIGNER_OAUTH_CLIENT_SECRET" \
      --data audience="https://cloud.nussknacker.io" | jq -r .access_token)
    
    if [ -z "$ACCESS_TOKEN" ] || [ "$ACCESS_TOKEN" == "null" ]; then
      red_echo "ERROR: Failed to fetch OAuth2 M2M access token\n"
      exit 4
    fi

    echo "NU_DESIGNER_AUTH_HEADER=\"Bearer $ACCESS_TOKEN\"" >> $NU_DESIGNER_CONFIG_FILE
    ;;
  *)
    red_echo "ERROR: Unsupported NU_DESIGNER_AUTH_MODE: $NU_DESIGNER_AUTH_MODE\n"
    exit 5
    ;;
esac