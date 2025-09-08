#!/usr/bin/env bash
set -Eeuo pipefail

# Guacamole initialization script

[ ! -d /var/run ] && mkdir -p /var/run

info "Starting Guacamole daemon..."

# Start guacd in background
exec /opt/guacamole/sbin/guacd -b 127.0.0.1 -L info -p /var/run/guacd.pid &

sleep 1

return 0