#!/bin/bash -ex

cd "$(dirname "$0")"

rm -rf nussknacker-installation-example
git clone https://github.com/TouK/nussknacker-installation-example.git
cd nussknacker-installation-example

function cleanup() {
  docker compose -f docker-compose.yml -f ../example-scenarios-library.override.yml logs
  docker compose -f docker-compose.yml -f ../example-scenarios-library.override.yml down -v 
}

trap cleanup EXIT

docker compose -f docker-compose.yml -f ../example-scenarios-library.override.yml up -d --build --remove-orphans --wait 
