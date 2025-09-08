#!/usr/bin/env bash
set -Eeuo pipefail

# Guacamole initialization script

[ ! -d /var/run ] && mkdir -p /var/run

info "Starting Guacamole daemon..."

# Start guacd in background
/opt/guacamole/sbin/guacd -b 127.0.0.1 -L info -p /var/run/guacd.pid &

sleep 2

# Verify guacd started
if [ -f /var/run/guacd.pid ]; then
    info "Guacamole daemon started successfully"
else
    warn "Guacamole daemon may not have started properly"
fi

return 0