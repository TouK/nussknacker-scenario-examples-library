#!/bin/bash -ex

cd "$(dirname "$0")"

cd ../../../
EXAMPLES_LIBABRY_BUILD_TEMP_VERSION=$(uuidgen | tr -d '-' | tr 'A-Z' 'a-z' | cut -c1-10)
echo "1. Building Scenario Examples Library image. Version: ${EXAMPLES_LIBABRY_BUILD_TEMP_VERSION}..."
docker buildx build --tag touk/nussknacker-example-scenarios-library:"$EXAMPLES_LIBABRY_BUILD_TEMP_VERSION" .

echo "2. Checking out Nu Quickstart..."
cd .github/workflows/scripts
rm -rf nussknacker-quickstart
git clone https://github.com/TouK/nussknacker-quickstart.git
cd nussknacker-quickstart
git checkout staging # TODO: change to main when Nu 1.17 is released

echo "3. Setting proper Scenario Examples Library image version..."
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s|touk/nussknacker-example-scenarios-library:latest|touk/nussknacker-example-scenarios-library:${EXAMPLES_LIBABRY_BUILD_TEMP_VERSION}|g" docker-compose.yml
else
  sed -i "s|touk/nussknacker-example-scenarios-library:latest|touk/nussknacker-example-scenarios-library:${EXAMPLES_LIBABRY_BUILD_TEMP_VERSION}|g" docker-compose.yml
fi

on_error() {
  docker compose logs 
}

on_exit() {
  echo "4. Cleanup"
  ./stop-and-clean.sh
  rm -rf ../nussknacker-quickstart
}

trap on_error ERR
trap on_exit EXIT

./start.sh