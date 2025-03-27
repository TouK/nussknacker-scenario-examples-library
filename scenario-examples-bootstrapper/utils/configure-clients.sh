#!/bin/bash -ex

cd "$(dirname "$0")"

source lib.sh

# Configure Kafka client
kafka/configure-kafka-client.sh

# Configure Nu client data
nu/create-nu-authorization-header-value.sh

if [ -v NU_DESIGNER_ADDRESS ] && ! [ -v NU_DESIGNER_URL ]; then
  orange_echo "WARN: Nu Designer address is provided but URL is not set, setting it to ${NU_DESIGNER_ADDRESS}"
  export NU_DESIGNER_URL="http://${NU_DESIGNER_ADDRESS}"
fi

# Configure Schema Registry client data 
schema-registry/create-schema-registry-authorization-header-value.sh

if [ -v SCHEMA_REGISTRY_ADDRESS ] && ! [ -v SCHEMA_REGISTRY_URL ]; then
  orange_echo "WARN: Schema Registry address is provided but URL is not set, setting it to ${SCHEMA_REGISTRY_ADDRESS}"
  export SCHEMA_REGISTRY_URL="http://${SCHEMA_REGISTRY_ADDRESS}"
fi