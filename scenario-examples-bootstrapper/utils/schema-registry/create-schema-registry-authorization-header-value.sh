#!/bin/bash -ex

cd "$(dirname "$0")"

source ../lib.sh

if [ ! -v SCHEMA_REGISTRY_USER ] || [ -z "$SCHEMA_REGISTRY_USER" ]; then
  export SCHEMA_REGISTRY_USER="admin"
  echo "SCHEMA_REGISTRY_USER not set or empty, using default: admin"
fi

if [ ! -v SCHEMA_REGISTRY_PASSWORD ] || [ -z "$SCHEMA_REGISTRY_PASSWORD" ]; then
  export SCHEMA_REGISTRY_PASSWORD="admin"
  echo "SCHEMA_REGISTRY_PASSWORD not set or empty, using default: admin"
fi

export SCHEMA_REGISTRY_AUTH_HEADER="-u $SCHEMA_REGISTRY_USER:$SCHEMA_REGISTRY_PASSWORD"
