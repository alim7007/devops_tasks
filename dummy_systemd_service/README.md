- ✅ 9. Dummy Systemd Service Task from https://roadmap.sh/projects/dummy-systemd-service

## Create service file
```bash
cd /etc/systemd/system
sudo vim dummy.service
```

[Unit]
Description=Dummy Systemd Service Task from Roadmap.sh

[Service]
ExecStart=/home/alim/dummy_systemd_service/dummy.sh

[Install]
WantedBy=multi-user.target

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now dummy.service
systemctl status dummy.service
```

Update the script in Git → push → CI/CD will rsync the new dummy.sh to the server and restart the service automatically.

```bash
sudo systemctl stop dummy
sudo systemctl disable dummy
```