#!/bin/bash -ex

cd "$(dirname "$0")"

source lib.sh

kafka/configure-kafka-client.sh
nu/configure-nu-client.sh
schema-registry/configure-schema-registry-client.sh
