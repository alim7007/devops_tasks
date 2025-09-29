- ✅ 8. Simple Monitoring Task from https://roadmap.sh/projects/simple-monitoring-dashboard

## Installation

Install Netdata and claim it to your Cloud workspace:

```bash
curl https://get.netdata.cloud/kickstart.sh > /tmp/netdata-kickstart.sh \
  && sh /tmp/netdata-kickstart.sh --claim-token YOUR_CLAIM_TOKEN
```

Access dashboards:
- Local: `http://<your-ip>:19999`
- Cloud: [https://app.netdata.cloud](https://app.netdata.cloud)

---

## Secure Access

By default, Netdata listens on port `19999`. Use `ufw` to control access:

```bash
# Allow for everyone (not recommended)
sudo ufw allow 19999/tcp

# Allow only your IP
sudo ufw allow from <YOUR_IP> to any port 19999 proto tcp

# Deny completely (use Cloud only)
sudo ufw deny 19999/tcp
```

---

## Nginx Monitoring

Enable the Nginx `stub_status` endpoint:

```bash
sudo vim /etc/nginx/conf.d/status.conf
```

Add:

```nginx
server {
    listen 127.0.0.1:18080;
    server_name 127.0.0.1;

    location /stub_status {
        stub_status;
        allow 127.0.0.1;
        deny all;
    }
}
```

Reload Nginx:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

---

### Netdata Collector Config

```bash
sudo vim /etc/netdata/go.d/nginx.conf
```

Add:

```yaml
jobs:
  - name: local
    url: http://127.0.0.1:18080/stub_status
```

Restart Netdata:

```bash
sudo systemctl restart netdata
```

Verify:

```bash
curl http://127.0.0.1:18080/stub_status
```

---

## Custom CPU Alert

Edit health config:

```bash
sudo /etc/netdata/edit-config health.d/cpu.conf
```

Add:

```yaml
alarm: cpu_over_80
on: system.cpu
lookup: average -5m unaligned of user,system,softirq,irq,guest
units: %
every: 10s
warn: $this > 80
crit: $this > 95
delay: up 1m down 2m
info: "Average CPU usage over 5 minutes is too high"
to: sysadmin
```

Reload:

```bash
sudo kill -HUP $(pidof netdata)
```
_or_
```bash
sudo systemctl restart netdata
```

---

## 🧪 Testing Alerts

Run CPU load:

```bash
yes > /dev/null &
yes > /dev/null &
```

Check in Netdata Cloud: **Metrics → System → CPU utilization**

Stop load:

```bash
killall yes
```

Reboot if package updates require:

```bash
sudo reboot
```