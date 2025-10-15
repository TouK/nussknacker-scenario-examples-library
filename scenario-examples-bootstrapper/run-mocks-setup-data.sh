#!/bin/bash

cd "$(dirname "$0")"

source /app/utils/lib.sh

rm -rf /app/.status
mkdir -p /app/.status

if /app/mocks/db/is-postgres-ready.sh && /app/mocks/http-service/is-wiremock-ready.sh; then
  # We configure error trap after we check that Postgres and Wiremock is ready.
  # Unavailability of these services is a normal situation because phusion/baseimage doesn't handle
  # dependencies checking/service startup ordering
  configure_error_handling
  green_echo "------ Nu scenarios library is being prepared... ---------\n"
  /app/utils/configure-clients.sh

  if are_embedded_examples_active; then 
    mkdir -p /scenario-examples
    if [ "$(ls -A /tmp/scenario-examples)" ]; then
      mv /tmp/scenario-examples/* /scenario-examples/ 2>/dev/null || true
    fi
  fi

  /app/mocks/configure.sh
  /app/setup/run-setup-before-designer-start.sh

  if /app/utils/nu/is-designer-ready.sh; then
    green_echo "------ Designer is ready. Importing scenarios... ---------\n"

    /app/setup/run-setup-after-designer-start.sh

    /app/data/keep-sending.sh

    green_echo "------ Nu scenarios library sucessfully bootstrapped! ----\n\n"

    touch /app/.status/healthy

    if [ "$STOP_WHEN_NO_GENERATOR_OR_MOCK_ENABLED" = "true" ]; then
      if [ ! -f /app/.status/generators-running ] && [ ! -f /app/.status/mocks-used ]; then
        green_echo "No generators or mocks used, stopping the library service..."
        exit 0
      fi
    fi

    # loop forever (you can use manually called utils scripts now)
    tail -f /dev/null

  else
    echo -e "\nWaiting for Designer to be up and ready...\n"
    sleep 5
    exit 1
  fi
else
  echo -e "\nWaiting for Postgres and Wiremock to be up and ready...\n"
  sleep 5
  exit 1
fi
