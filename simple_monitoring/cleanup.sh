#!/bin/bash
set -e

echo ">>> Stopping test load..."
killall yes 2>/dev/null || true

# echo ">>> Removing Netdata..."
# sudo systemctl stop netdata || true
# sudo apt remove --purge -y netdata || true
# sudo rm -rf /etc/netdata /var/lib/netdata /usr/libexec/netdata

# echo ">>> Cleaning Nginx stub_status config..."
# sudo rm -f /etc/nginx/conf.d/status.conf
# sudo systemctl reload nginx

echo ">>> Cleanup done."
