#!/bin/bash -e

cd "$(dirname "$0")"

source ../lib.sh

if ! [ -v KAFKA_AUTH_MODE ]; then
  echo "KAFKA_AUTH_MODE not set, using default value 'NO_AUTH'"
  export KAFKA_AUTH_MODE="NO_AUTH"
fi

function setup_no_auth_kafka_client() {
  if ! [ -v KAFKA_ADDRESS ] || [ -z "$KAFKA_ADDRESS" ]; then
    red_echo "ERROR: When NO_AUTH is used, KAFKA_ADDRESS must be set and not empty"
    exit 21
  fi

  mkdir -p ~/.kafka
  cat <<EOF > ~/.kafka/config
current-cluster: local
clusteroverride: ""
clusters:
- name: local
  version: ""
  brokers:
  - $KAFKA_ADDRESS
  SASL: null
  TLS: null
  security-protocol: null
  schema-registry-url: ""
  schema-registry-credentials: null
EOF
}

function setup_file_defined_auth_kafka_client() {
  if [ -v KAFKA_ADDRESS ]; then
    orange_echo "WARN: when FILE_DEFINED_AUTH is used, KAFKA_ADDRESS is ignored\n"
  fi

  if [ ! -f ~/.kafka/config ]; then
    red_echo "ERROR: ~/.kafka/config does not exist. When you use FILE_DEFINED_AUTH, you must provide kaf tool configuration (see https://github.com/birdayz/kaf/tree/master/examples)"
    exit 32
  fi  

  if ! kaf topics ls > /dev/null 2>&1; then
    red_echo "ERROR: Cannot connect to Kafka using provided configuration:"
    kaf topics ls
    exit 33
  fi
}

case "$KAFKA_AUTH_MODE" in
  "NO_AUTH")
    setup_no_auth_kafka_client
    ;;
  "FILE_DEFINED_AUTH")
    setup_file_defined_auth_kafka_client
    ;;
  *)  
    red_echo "ERROR: no such auth mode: $KAFKA_AUTH_MODE"
    exit 1
    ;;
esac
