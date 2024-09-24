#!/bin/bash -e

cd "$(dirname "$0")"

source ../../utils/lib.sh

if [ "$#" -ne 1 ]; then
    red_echo "ERROR: One parameter required: 1) scenario example folder path\n"
    exit 1
fi

function execute_flink_sql_file() {
  if [ "$#" -ne 1 ]; then
    red_echo "ERROR: One parameter required: 1) Flink SQL file\n"
    exit 11
  fi
  
  set -e

  local FLINK_SQL_FILE_PATH=$1
  
  echo "Executing Flink SQL file '$(basename "$FLINK_SQL_FILE_PATH")'... "
  ../../utils/flink/execute-flink-sql-scripts.sh "$FLINK_SQL_FILE_PATH"
}

SCENARIO_EXAMPLE_DIR_PATH=${1%/}

echo "Starting to execute Flink DML scripts..."

shopt -s nullglob

for ITEM in "$SCENARIO_EXAMPLE_DIR_PATH/data/flink/static"/*; do
  if [ ! -f "$ITEM" ]; then
    continue
  fi

  if [[ ! "$ITEM" == *.sql ]]; then
    red_echo "ERROR: Unrecognized file $ITEM. Required file with extension '.sql' and content with DML statements\n"
    exit 3
  fi

  execute_flink_sql_file "$ITEM"
done

echo -e "Flink DML scripts executed!\n"
