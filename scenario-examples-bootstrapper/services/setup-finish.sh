#!/bin/sh

if [ "$1" = "0" ]; then
  sv stop /etc/service/setup
  sv stop /etc/service/http-service
  sv stop /etc/service/db
  exit 0
fi 