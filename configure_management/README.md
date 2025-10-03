- ✅ 12. Configuration Management Task from https://roadmap.sh/projects/configuration-management

Use **Ansible** to configure a Linux server with roles:

* `base` — updates + utilities + firewall + fail2ban
* `nginx` — install & configure NGINX
* `app` — upload a static site tar and unpack it
* `ssh` — add a public key to the server

---

## 0) Installing Ansible (system install)

If you’re installing Ansible on Ubuntu the “old school” way:

```bash
sudo apt update
sudo apt install ansible
```

> In this repo we also provide a **project-local toolchain** (preferred):
> `make bootstrap` → creates `.venv/` and installs pinned Ansible + vendored Galaxy deps.

---

## 1) SSH key (avoid passphrase prompts)

```bash
# start agent (macOS usually has one already)
eval "$(ssh-agent -s)"

# load your key once per login session (will prompt for passphrase)
ssh-add ~/.ssh/id_ed25519

# verify it's loaded
ssh-add -l
```

**First time to a host:** SSH once so the fingerprint is known (host key gets written to `~/.ssh/known_hosts`).

---

## 2) Galaxy collections

Your original command (keep it if your file is named exactly this):

```bash
ansible-galaxy collection install -r ansible/collections/requirements.yaml
```

In this repo we use:

```bash
make bootstrap
# (internally runs: ansible-galaxy collection install -r ansible/requirements/collections.yaml)
```

---

## 3) Playbook notes (short + practical)

* `- hosts: all`
  A play that targets every host from your inventory. You could use a group like `servers` instead.

* `gather_facts: true`
  Useful for conditionals (e.g., service name differences). Lets you branch with `when:` (e.g., only run `apt` on Debian).

* `become: true`
  Run tasks with sudo/root on the remote hosts. (Your SSH user may be non-root; Ansible will escalate.)

* `update_cache: true`
  ≈ `apt-get update` (refresh package metadata).

* **Idempotence**
  Ansible modules (`apt`, `user`, `lineinfile`, …) check current state and only act **if needed**.

---

## 4) Ansible Galaxy (what it is)

Ansible Galaxy = public repository of community-maintained **roles** and **collections**.
Website: [https://galaxy.ansible.com](https://galaxy.ansible.com)

**Example** (using a role like `geerlingguy.nginx`):

```yaml
- hosts: webservers
  roles:
    - geerlingguy.nginx
```

That one line will install NGINX, configure it, manage the service, etc.

**Best practice today:** use **FQCN** (fully qualified collection name), e.g. `ansible.builtin.service`.
Reason: avoids ambiguity if you install third-party collections that also ship a `service` module.

* `ansible.builtin.service` → works everywhere; on systemd machines it calls systemd **indirectly**.
* `ansible.builtin.systemd` → talks to `systemctl` **directly** and exposes systemd-only features.

Example:

```yaml
- name: Restart nginx with systemd
  ansible.builtin.systemd:
    name: nginx
    state: restarted
# (or use ansible.builtin.service with state: restarted)
```

---

## 5) Editing sudoers safely

`/etc/sudoers` breaks → sudo stops working.
`visudo` edits safely and checks syntax before saving.

What Ansible does in our playbook:

* writes to `/etc/sudoers.d/USERNAME` (safer than editing the main file)
* validates with `visudo -cf %s` before applying

---

## 6) Running things

### Using **Make** (recommended)

```bash
# set up pinned toolchain + vendored deps (one time per clone)
make bootstrap

# dry-run after initial converge (preview only)
make check LIMIT=server2

# apply everything to server2
make apply LIMIT=server2

# run only one role
make tags TAG=nginx LIMIT=server2
make tags TAG=app   LIMIT=server2
```

### Plain Ansible equivalents

```bash
# Dry-run roles for server2 only
ansible-playbook ansible/playbooks/setup.yaml --limit server2 --check --diff

# Apply roles to server2 only
ansible-playbook ansible/playbooks/setup.yaml --limit server2

# Apply only the nginx role on server2
ansible-playbook ansible/playbooks/setup.yaml --limit server2 --tags nginx

# Apply only the app role on server2
ansible-playbook ansible/playbooks/setup.yaml --limit server2 --tags app
```

> **Note on `--check`:** it’s a **best-effort preview**. Package installs don’t happen in check mode; don’t expect it to behave like Terraform **plan** on a totally fresh box.

---

## 7) Optional roles file

`requirements/roles.yaml` (optional Galaxy roles)

```yaml
---
roles: []
```

You’re implementing `base/nginx/app/ssh` yourself, so this can stay empty.
(If later you add third-party roles, pin them here and vendor them.)

---

## 8) NGINX + App specifics (crucial)

* Open firewall for HTTP (and later HTTPS):

```bash
sudo ufw allow "Nginx HTTP"
# sudo ufw allow "Nginx Full"   # 80 + 443
```

* Disable Ubuntu’s packaged default site (to avoid duplicate `default_server`):

```bash
sudo rm -f /etc/nginx/sites-enabled/default
sudo systemctl reload nginx
```

* Our app role **flattens** `website.tar.gz` into the web root with:

```yaml
extra_opts: ['--strip-components=1']
```

So `index.html` ends up at `/var/www/html/index.html` (no nested folder).

---

## 9) Quick verification (copy/paste)

```bash
# reachability + sudo
ansible server2 -m ping
ansible server2 -b -m command -a "whoami"          # expect: root

# nginx
ansible server2 -m command -a "nginx -t"
ansible server2 -m command -a "systemctl is-active nginx"
ansible server2 -m uri -a "url=http://<SERVER2_IP> status_code=200"

# app content
ansible server2 -m shell -a "test -f /var/www/html/index.html && echo OK || echo MISSING"

# firewall
ansible server2 -m command -a "ufw status verbose"

# fail2ban
ansible server2 -m command -a "systemctl is-active fail2ban"
ansible server2 -b -m command -a "fail2ban-client status"
```

---

## 10) Handy one-liners

```bash
# Syntax check only (fast)
ansible-playbook ansible/playbooks/setup.yaml --syntax-check

# See what will run / available tags
ansible-playbook ansible/playbooks/setup.yaml --list-tasks
ansible-playbook ansible/playbooks/setup.yaml --list-tags
```

---

## 11) Notes for later (CI/CD)

* Keep using the **project-local venv** (no global clutter).
* In CI, run the same `make bootstrap && make check/apply` with a self-hosted runner or a bastion that can reach your servers.

---

############
"make check" is not like "terraform plan"
############