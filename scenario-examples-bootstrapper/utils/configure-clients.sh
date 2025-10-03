#!/bin/bash

cd "$(dirname "$0")"

source lib.sh
configure_error_handling

kafka/configure-kafka-client.sh
nu/configure-nu-client.sh
schema-registry/configure-schema-registry-client.sh
flink/configure-flink-sql-gateway-client.sh