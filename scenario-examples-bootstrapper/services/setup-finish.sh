#!/bin/sh

if [ "$1" = "0" ]; then
  pkill runsvdir
  exit 0
fi 