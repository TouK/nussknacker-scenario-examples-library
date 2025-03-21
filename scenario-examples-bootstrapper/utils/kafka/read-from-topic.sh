#!/bin/bash -e

cd "$(dirname "$0")"

source ../lib.sh

if [ "$#" -ne 1 ]; then
  red_echo "ERROR: One parameter required: 1) topic name\n"
  exit 1
fi

TOPIC_NAME=$1

if kaf --config /configs/kaf topics ls | awk '{print $1}' | grep "^$TOPIC_NAME$" > /dev/null 2>&1; then
  kaf --config /configs/kaf consume "$TOPIC_NAME" --offset oldest --output raw
else
  red_echo "ERROR: Topic name '$TOPIC_NAME' not found\n"
  exit 2
fi