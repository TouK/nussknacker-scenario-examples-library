#!/bin/bash -ex

cd "$(dirname "$0")"

source ../lib.sh

SCHEMA_REGISTRY_CONFIG_FILE="/configs/schema-registry"
rm -f $SCHEMA_REGISTRY_CONFIG_FILE
touch $SCHEMA_REGISTRY_CONFIG_FILE

if [ -v SCHEMA_REGISTRY_ADDRESS ] && ! [ -v SCHEMA_REGISTRY_URL ]; then
  orange_echo "WARN: Schema Registry address is provided but URL is not set, setting it to ${SCHEMA_REGISTRY_ADDRESS}"
  echo "SCHEMA_REGISTRY_URL=http://${SCHEMA_REGISTRY_ADDRESS}" >> $SCHEMA_REGISTRY_CONFIG_FILE
fi

if [ ! -v SCHEMA_REGISTRY_USER ] || [ -z "$SCHEMA_REGISTRY_USER" ]; then
  SCHEMA_REGISTRY_USER="admin"
  echo "SCHEMA_REGISTRY_USER not set or empty, using default: admin"
fi

if [ ! -v SCHEMA_REGISTRY_PASSWORD ] || [ -z "$SCHEMA_REGISTRY_PASSWORD" ]; then
  SCHEMA_REGISTRY_PASSWORD="admin"
  echo "SCHEMA_REGISTRY_PASSWORD not set or empty, using default: admin"
fi

echo "SCHEMA_REGISTRY_AUTH_HEADER=$SCHEMA_REGISTRY_USER:$SCHEMA_REGISTRY_PASSWORD" >> $SCHEMA_REGISTRY_CONFIG_FILE
