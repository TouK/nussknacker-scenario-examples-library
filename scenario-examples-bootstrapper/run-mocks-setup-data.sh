#!/bin/bash -e

cd "$(dirname "$0")"

source /app/utils/lib.sh

rm -rf /app/healthy

/app/utils/kafka/configure-kafka-client.sh
/app/utils/nu/create-nu-authorization-header-value.sh

if /app/mocks/db/is-postgres-ready.sh && /app/mocks/http-service/is-wiremock-ready.sh; then
  green_echo "------ Nu scenarios library is being prepared... ---------\n"
  
  if are_embedded_examples_active; then 
    mkdir -p /scenario-examples
    if [ "$(ls -A /tmp/scenario-examples)" ]; then
      mv /tmp/scenario-examples/* /scenario-examples/
    fi
  fi

  /app/mocks/configure.sh
  /app/setup/run-setup.sh
  /app/data/keep-sending.sh
  
  green_echo "------ Nu scenarios library sucessfully bootstrapped! ----\n\n"
  
  touch /app/healthy
  
  export GENERATORS_USED=false
  export MOCKS_USED=false

  if [ "$STOP_WHEN_NO_GENERATOR_OR_MOCK_ENABLED" = "true" ]; then 
    if [ "$GENERATORS_USED" = "false" ] && [ "$MOCKS_USED" = "false" ]; then
      green_echo "No generators or mocks used, stopping the library service..."
      exit 0
    fi
  fi

  # loop forever (you can use manually called utils scripts now)
  tail -f /dev/null
else
  echo -e "\nWaiting for Postgres and Wiremock to be up and ready...\n"
  sleep 5
  exit 1
fi
