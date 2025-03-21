#!/bin/sh 

exec /app/utils/kafka/configure-kafka-client.sh
exec /app/run-mocks-setup-data.sh