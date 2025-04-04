#!/bin/bash -e

cd "$(dirname "$0")"

source ../lib.sh

if [ "$#" -ne 1 ]; then
  red_echo "ERROR: One parameter required: 1) topic name\n"
  exit 1
fi

TOPIC_NAME=$1

kaf --config /configs/kaf topic delete "$TOPIC_NAME" > /dev/null
sleep 0.5
./create-topic-idempotently.sh "$TOPIC_NAME"
