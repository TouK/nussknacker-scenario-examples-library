#!/bin/bash -ex

cd "$(dirname "$0")"

source ../lib.sh

FLINK_SQL_GATEWAY_CONFIG_FILE="/configs/flink-sql-gateway"
rm -f $FLINK_SQL_GATEWAY_CONFIG_FILE
touch $FLINK_SQL_GATEWAY_CONFIG_FILE

if [ -v FLINK_SQL_GATEWAY_ADDRESS ] && ! [ -v FLINK_SQL_GATEWAY_URL ]; then
  orange_echo "WARN: Flink SQL Gateway address is provided but URL is not set, setting it to ${FLINK_SQL_GATEWAY_ADDRESS}"
  echo "FLINK_SQL_GATEWAY_URL=http://${FLINK_SQL_GATEWAY_ADDRESS}" >> $FLINK_SQL_GATEWAY_CONFIG_FILE
fi
