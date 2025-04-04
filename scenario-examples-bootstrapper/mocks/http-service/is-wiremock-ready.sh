#!/bin/bash -e

if [ -f /app/.status/mocks-used ]; then
  curl -f -s http://localhost:8080/__admin/ > /dev/null
fi
