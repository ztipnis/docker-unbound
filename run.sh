#!/bin/sh
echo "Starting Unbound..."
if [ ! -f "/config/unbound/unbound.conf" ]; then
  cp /opt/unbound/etc/unbound/unbound.conf /config/unbound/unbound.conf
fi
/opt/unbound/sbin/unbound-control-setup -d /config/unbound
/opt/unbound/sbin/unbound-anchor
/opt/unbound/sbin/unbound-checkconf
set -o xtrace
exec /opt/unbound/sbin/unbound -d -c /config/unbound/unbound.conf "$@"