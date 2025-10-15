#!/bin/bash -e

cd "$(dirname "$0")"

source /configs/nu-designer

if ! [ -v NU_DESIGNER_URL ] || [ -z "$NU_DESIGNER_URL" ]; then
  red_echo "ERROR: required variable NU_DESIGNER_URL not set or empty\n"
  exit 2
fi

curl -f -s "${NU_DESIGNER_URL}/api/app/healthCheck" > /dev/null
