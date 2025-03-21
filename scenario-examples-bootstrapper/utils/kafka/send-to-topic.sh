#!/bin/bash -e

cd "$(dirname "$0")"

source ../lib.sh

if [ "$#" -ne 2 ]; then
  red_echo "ERROR: Two parameters required: 1) topic name, 2) messages (message per line)\n"
  exit 1
fi

TOPIC_NAME=$1
MESSAGES=$2

if kaf --config /configs/kaf topics ls | awk '{print $1}' | grep "^$TOPIC_NAME$" > /dev/null 2>&1; then
  echo "$MESSAGES" | kaf --config /configs/kaf produce "$TOPIC_NAME" > /dev/null
else
  red_echo "ERROR: Topic name '$TOPIC_NAME' not found\n"
  exit 3
fi