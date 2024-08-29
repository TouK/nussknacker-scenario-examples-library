#!/bin/bash -e

cd "$(dirname "$0")"

source ./version

docker build -t "touk/nussknacker-example-scenarios-library:${LIBRARY_DOCKER_IMAGE_VERSION}" -f Dockerfile .