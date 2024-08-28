#!/bin/bash -e

cd "$(dirname "$0")"

source ./version

./build-docker-image.sh

docker push "touk/nussknacker-example-scenarios-library${LIBRARY_DOCKER_IMAGE_VERSION}"