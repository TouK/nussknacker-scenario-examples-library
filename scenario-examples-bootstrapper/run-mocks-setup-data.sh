#!/bin/bash -e

cd "$(dirname "$0")"

source /app/utils/lib.sh

rm -rf /app/healthy

if [ ! -v NU_DESIGNER_USER ] || [ -z "$NU_DESIGNER_USER" ]; then
  export NU_DESIGNER_USER="admin"
  echo "NU_DESIGNER_USER not set or empty, using default: admin"
fi

if [ ! -v NU_DESIGNER_PASSWORD ] || [ -z "$NU_DESIGNER_PASSWORD" ]; then
  export NU_DESIGNER_PASSWORD="admin"
  echo "NU_DESIGNER_PASSWORD not set or empty, using default: admin"
fi

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
  
  # loop forever (you can use manually called utils scripts now)
  tail -f /dev/null
else
  echo -e "\nWaiting for Postgres and Wiremock to be up and ready...\n"
  sleep 5
  exit 1
fi
