FROM holomekc/wiremock-gui:3.8.1 AS wiremock

RUN apt-get update && \ 
    apt-get install -y wget && \
    wget -P /var/wiremock/extensions https://repo1.maven.org/maven2/org/wiremock/extensions/wiremock-faker-extension-standalone/0.2.0/wiremock-faker-extension-standalone-0.2.0.jar

FROM phusion/baseimage:noble-1.0.2

ENTRYPOINT ["/entrypoint.sh"]

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

# phusion/baseimage starts syslog-ng, cron and sshd - we don't need them
RUN rm /etc/my_init.d/10_syslog-ng.init && \
    rm /etc/my_init.post_shutdown.d/10_syslog-ng.shutdown && \
    rm /etc/my_init.d/00_regen_ssh_host_keys.sh && \
    rm -rf /etc/service/cron && \
    rm -rf /etc/service/sshd

# WIREMOCK & POSTGRES
COPY --from=wiremock /var/wiremock /var/wiremock
COPY --from=wiremock /home/wiremock /home/wiremock

EXPOSE 8080
EXPOSE 5432

COPY entrypoint.sh /entrypoint.sh
COPY healthcheck.sh /healthcheck.sh

COPY scenario-examples-bootstrapper/setup/ /app/setup/
COPY scenario-examples-bootstrapper/mocks/ /app/mocks/
COPY scenario-examples-bootstrapper/data/ /app/data/
COPY scenario-examples-bootstrapper/utils/ /app/utils/
COPY scenario-examples-bootstrapper/run-mocks-setup-data.sh /app/run-mocks-setup-data.sh

COPY scenario-examples-bootstrapper/services/postgres.sh /etc/service/db/run
COPY scenario-examples-bootstrapper/services/wiremock.sh /etc/service/http-service/run
COPY scenario-examples-bootstrapper/services/setup.sh /etc/service/setup/run
COPY scenario-examples-bootstrapper/services/setup-finish.sh /etc/service/setup/finish

COPY scenario-examples-library/ /tmp/scenario-examples

# this is a default healthcheck. You can override it by setting HEALTHCHECK in docker-compose.yml
HEALTHCHECK --interval=10s --timeout=1s --retries=30 --start-period=60s \
  CMD /healthcheck.sh
