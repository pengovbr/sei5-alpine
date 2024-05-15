#!/bin/sh

mkdir -p /opt/sei/temp
mkdir -p /opt/sip/temp
chmod 777 /opt/sei/temp
chmod 777 /opt/sip/temp

exec "$@"
