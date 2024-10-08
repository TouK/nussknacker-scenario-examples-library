FROM holomekc/wiremock-gui:3.8.1 AS wiremock

RUN apt-get update && \ 
    apt-get install -y wget && \
    wget -P /var/wiremock/extensions https://repo1.maven.org/maven2/org/wiremock/extensions/wiremock-faker-extension-standalone/0.2.0/wiremock-faker-extension-standalone-0.2.0.jar

FROM phusion/baseimage:noble-1.0.0

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

WORKDIR /app

USER root

RUN apt update && \
    apt install -y --no-install-recommends curl ca-certificates jq less && \
    install -d /usr/share/postgresql-common/pgdg && \
    curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc && \
    echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    apt update -y && \
    apt -y install postgresql-16 && \
    apt -y install openjdk-11-jre-headless && \
    apt clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    curl https://raw.githubusercontent.com/birdayz/kaf/master/godownloader.sh | BINDIR=/bin bash 

# WIREMOCK & POSTGRES
COPY --from=wiremock /var/wiremock /var/wiremock
COPY --from=wiremock /home/wiremock /home/wiremock

EXPOSE 8080
EXPOSE 5432

COPY scenario-examples-bootstrapper/setup/ /app/setup/
COPY scenario-examples-bootstrapper/mocks/ /app/mocks/
COPY scenario-examples-bootstrapper/data/ /app/data/
COPY scenario-examples-bootstrapper/utils/ /app/utils/
COPY scenario-examples-bootstrapper/run-mocks-setup-data.sh /app/run-mocks-setup-data.sh

COPY scenario-examples-bootstrapper/services/postgres.sh /etc/service/db/run
COPY scenario-examples-bootstrapper/services/wiremock.sh /etc/service/http-service/run
COPY scenario-examples-bootstrapper/services/setup.sh /etc/service/setup/run

COPY scenario-examples-library/ /tmp/scenario-examples

HEALTHCHECK --interval=10s --timeout=1s --retries=12 --start-period=30s \
  CMD (/app/setup/is-setup-done.sh && /app/mocks/db/is-postgres-ready.sh && /app/mocks/http-service/is-wiremock-ready.sh) || exit 1
