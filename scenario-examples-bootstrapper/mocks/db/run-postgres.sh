#!/bin/bash

cd "$(dirname "$0")"

source postgres-operations.sh
source ../../utils/lib.sh
configure_error_handling

echo "Starting Postgres service..."

./postgres-init.sh

stop() {
  echo "Stopping Postgres service..."
  postgres_stop
}

trap stop EXIT

postgres_start
