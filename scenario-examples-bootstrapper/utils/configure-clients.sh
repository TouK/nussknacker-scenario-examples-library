#!/bin/bash -e

cd "$(dirname "$0")"

kafka/configure-kafka-client.sh
nu/create-nu-authorization-header-value.sh
schema-registry/create-schema-registry-authorization-header-value.sh
