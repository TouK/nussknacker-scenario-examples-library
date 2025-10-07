#!/bin/bash -e

/app/setup/is-setup-done.sh && \
  ([ ! -f /app/.status/mocks-used ] || \
    (/app/mocks/db/is-postgres-ready.sh && \
     /app/mocks/http-service/is-wiremock-ready.sh)) || exit 1

exit 0