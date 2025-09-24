#!/bin/bash
set -e

echo ">>> Installing Netdata..."
curl https://get.netdata.cloud/kickstart.sh > /tmp/netdata-kickstart.sh
sh /tmp/netdata-kickstart.sh --claim-token YOUR_CLAIM_TOKEN

echo ">>> Configuring UFW..."
sudo ufw allow 19999/tcp || true

echo ">>> Configuring Nginx stub_status..."
cat <<EOF | sudo tee /etc/nginx/conf.d/status.conf
server {
    listen 127.0.0.1:18080;
    server_name 127.0.0.1;

    location /stub_status {
        stub_status;
        allow 127.0.0.1;
        deny all;
    }
}
EOF

sudo nginx -t
sudo systemctl reload nginx

echo ">>> Configuring Netdata nginx collector..."
cat <<EOF | sudo tee /etc/netdata/go.d/nginx.conf
jobs:
  - name: local
    url: http://127.0.0.1:18080/stub_status
EOF

sudo systemctl restart netdata

echo ">>> Setup complete. Visit http://<IP>:19999 or Netdata Cloud."
