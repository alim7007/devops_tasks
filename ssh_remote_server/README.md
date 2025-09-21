- SSH Remote Server Setup Task from https://roadmap.sh/projects/ssh-remote-server-setup

- For generating keys
```bash
ssh-keygen -t ed25519 -C "digital_ocean" -f ~/.ssh/digital_ocean
````

* For not passing passphrase all the time

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/digital_ocean
```

* For alias put inside \~/.ssh/config

```ssh-config
Host do-first
    HostName 188.166.167.157
    User root
    IdentityFile ~/.ssh/digital_ocean
```

* For passing public key to server, if did not add directly while creating server.

```bash
ssh-copy-id -i ~/.ssh/digital_ocean.pub root@server-ip
```

* Choose a public IPv4 address for connection via ssh server-ip.

* fail2ban

```bash
sudo apt update
sudo apt install fail2ban
systemctl status fail2ban.service
cd /etc/fail2ban
```

Views first 20 lines of the default jail config.

```bash
head -20 jail.conf
```

Copies default config → jail.local (your editable version, safe from updates).

```bash
sudo cp jail.conf jail.local
```

To customize yourself.

```bash
sudo vim jail.local
```

Lists available filters (regex rules for services like sshd, nginx, etc.).

```bash
ls /etc/fail2ban/filter.d
```

Enables Fail2ban to auto-start at boot.

```bash
sudo systemctl enable fail2ban
```

Starts Fail2ban service now.

```bash
sudo systemctl start fail2ban
```

Confirms it’s running after your edits.

```bash
sudo systemctl status fail2ban
```