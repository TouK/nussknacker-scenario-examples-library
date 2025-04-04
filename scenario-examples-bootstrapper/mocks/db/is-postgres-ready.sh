#!/bin/bash -e

if [ -f /app/.status/mocks-used ]; then
  pg_isready -d mocks -U mocks > /dev/null
fi
