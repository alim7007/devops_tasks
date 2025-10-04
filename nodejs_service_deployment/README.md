- ✅ 14. Node.js Service Deployment Task from https://roadmap.sh/projects/nodejs-service-deployment


# Node.js Service Deployment with CI/CD

Automated deployment of a Node.js Express application to DigitalOcean infrastructure using Terraform, Ansible, and GitHub Actions with a self-hosted runner.

## Project Overview

This project demonstrates automated deployment of a Node.js service behind NGINX reverse proxy and load balancer, utilizing:
- **Terraform** for infrastructure provisioning
- **Ansible** for configuration management
- **GitHub Actions** with self-hosted runner for CI/CD
- **PM2** for Node.js process management
- **ProxyJump SSH** for secure bastion access

## Architecture

```
Internet → Load Balancer (64.225.82.128)
              ↓
          Web Servers (192.168.22.3, .4)
              ↓ Port 80
          NGINX Reverse Proxy
              ↓ localhost:3000
          Node.js App (PM2)

Access Path:
GitHub → Self-Hosted Runner (64.227.71.89, 192.168.22.7)
           ↓ SSH via ProxyJump
         Bastion (152.42.135.12, 192.168.22.2)
           ↓ Private Network
         Web Servers
```

## Infrastructure Components

### Existing Infrastructure (from `../iac_on_digital_ocean/`)

The base infrastructure was already provisioned:
- **VPC**: `192.168.22.0/24` in `ams3` region
- **Bastion**: `152.42.135.12` (public), `192.168.22.2` (private)
- **Web Servers**: 2 droplets (`192.168.22.3`, `192.168.22.4`)
- **Load Balancer**: `64.225.82.128` (HTTP only, port 80)
- **Database**: PostgreSQL cluster (not used in this project)

### New Infrastructure (this project)

**CI/CD Runner Droplet** (`terraform/`):
- **Purpose**: Runs GitHub Actions runner, executes Ansible playbooks
- **Location**: Inside same VPC (`192.168.22.7`)
- **Public IP**: `64.227.71.89`
- **Size**: `s-1vcpu-1gb` (sufficient for CI/CD tasks)
- **OS**: Ubuntu 25.04
- **SSH Access**: Uses separate SSH key pair generated on the runner itself

## Setup Process

### Phase 1: Infrastructure Provisioning

#### 1.1 CI/CD Droplet Creation

Created `terraform/` directory with Terraform configuration to provision CI/CD runner:

**Files created:**
- `cicd.tf` - Droplet resource
- `data.tf` - References to existing VPC and SSH key
- `variables.tf` - Configuration variables
- `outputs.tf` - Outputs CI/CD public/private IPs
- `main.tf` - Provider configuration
- `versions.tf` - Terraform and provider versions

**Key decision**: Placed CI/CD runner **inside the VPC** for:
- Private network communication with bastion (no bandwidth charges)
- Faster, more secure connections
- Ability to use private IPs

**Commands executed:**
```bash
cd nodejs_service_deployment/terraform
export TF_VAR_do_token="your_token"
terraform init
terraform apply
# Output: 64.227.71.89 (public), 192.168.22.7 (private)
```

#### 1.2 Bastion Firewall Update

**Problem**: Bastion firewall only allowed SSH from personal laptop IP (`your_ip/32`).

**Solution**: Updated `../iac_on_digital_ocean/variables.tf` to allow SSH from CI/CD runner's **private IP**:

```terraform
variable "allowed_ssh_cidrs" {
  default = ["your_ip/32", "192.168.22.7/32"]  # Added CI/CD private IP
}
```

**Why private IP?** Because both bastion and CI/CD runner are in the same VPC, using private IPs is more secure and doesn't consume public bandwidth.

Applied changes:
```bash
cd ../iac_on_digital_ocean
terraform apply
```

#### 1.3 Web Server Firewall Update

Added port 3000 to web server firewall in `../iac_on_digital_ocean/servers.tf` for testing/debugging purposes:

```terraform
inbound_rule {
  protocol         = "tcp"
  port_range       = "3000"
  source_addresses = ["192.168.22.0/24"]  # Only from VPC
}
```

**Note**: In production, this port should remain closed; NGINX reverse proxy is the only entry point.

### Phase 2: SSH Key Management & Access Configuration

#### 2.1 SSH Key Generation

**On CI/CD runner** (as root):
```bash
ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519
```

This created a **new, dedicated key pair** for the CI/CD runner (not reusing personal laptop keys).

#### 2.2 User Setup

Created `github-runner` user and copied **only the private key**:
```bash
useradd -m -s /bin/bash github-runner
mkdir -p /home/github-runner/.ssh
cp /root/.ssh/id_ed25519 /home/github-runner/.ssh/
chown -R github-runner:github-runner /home/github-runner/.ssh
chmod 600 /home/github-runner/.ssh/id_ed25519
```

#### 2.3 Public Key Distribution

Manually added the CI/CD runner's **public key** to three servers:

**On Bastion** (`152.42.135.12`):
```bash
vim /root/.ssh/authorized_keys
# Added: ssh-ed25519 AAAAC3NzaC...2dOJtx root@cicd-tf-digitalocean-ams3-1
```

**On web1** (`192.168.22.4`) and **web2** (`192.168.22.3`):
Same process - appended public key to each server's `/root/.ssh/authorized_keys`.

**Result**: All three servers trust the CI/CD runner's key.

#### 2.4 ProxyJump Configuration

Created `/home/github-runner/.ssh/config` on CI/CD runner:

```
Host do-bastion
    HostName 192.168.22.2
    User root
    IdentityFile /home/github-runner/.ssh/id_ed25519
    StrictHostKeyChecking no

Host web1
    HostName 192.168.22.4
    User root
    ProxyJump do-bastion

Host web2
    HostName 192.168.22.3
    User root
    ProxyJump do-bastion
```

**Key points:**
- Bastion referenced by **private IP** (`192.168.22.2`) since both are in same VPC
- `StrictHostKeyChecking no` avoids host key verification prompts in automation
- Web servers configured with `ProxyJump do-bastion` for automatic two-hop SSH

**Testing:**
```bash
sudo -u github-runner ssh do-bastion  # Direct to bastion
sudo -u github-runner ssh web1        # Through bastion to web1
```

### Phase 3: Ansible Configuration

All Ansible work done in `../configure_management/ansible/`.

#### 3.1 Inventory Update

Updated `inventory/hosts.ini` with new `webservers` group:

```ini
[webservers]
web1 ansible_host=192.168.22.4 ansible_user=root
web2 ansible_host=192.168.22.3 ansible_user=root

[webservers:vars]
ansible_ssh_common_args='-o ProxyJump=do-bastion'
```

**How it works:** 
- Ansible uses the `do-bastion` alias from SSH config
- Automatically routes through bastion using ProxyJump
- No need to specify bastion IP in Ansible inventory

#### 3.2 Created `nodejs` Role

Path: `roles/nodejs/tasks/main.yaml`

Installs Node.js 20.x, npm, and PM2 globally:
```yaml
- name: Install Node.js repository
  ansible.builtin.shell: curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
  
- name: Install Node.js and npm
  ansible.builtin.apt:
    name: nodejs
    state: present
    
- name: Install PM2 globally
  community.general.npm:
    name: pm2
    global: yes
```

**One-time setup** - only needs to run once per server.

#### 3.3 Created `node_app` Role

Path: `roles/node_app/tasks/main.yaml`

Deploys application using "clone and move" approach:

```yaml
- name: Clone repo
  ansible.builtin.git:
    repo: 'https://github.com/alim7007/devops_tasks.git'
    dest: /tmp/devops_tasks
    
- name: Copy node-app folder
  ansible.builtin.copy:
    src: /tmp/devops_tasks/nodejs_service_deployment/node-app/
    dest: /opt/node-app/
    remote_src: yes

- name: Clean up temp clone
  ansible.builtin.file:
    path: /tmp/devops_tasks
    state: absent
    
- name: Install dependencies
  community.general.npm:
    path: /opt/node-app
    
- name: Stop existing PM2 processes
  ansible.builtin.shell: pm2 delete all || true
  ignore_errors: true
  
- name: Start app with PM2
  ansible.builtin.shell: pm2 start app.js --name node-service
  args:
    chdir: /opt/node-app
    
- name: Save PM2 process list
  ansible.builtin.shell: pm2 save
```

**Why this approach?** 
- Node.js app lives in monorepo alongside infrastructure code
- Git doesn't support cloning subdirectories
- Solution: Clone entire repo to `/tmp`, extract only `node-app/` folder, cleanup

**Runs on every deployment** to update code.

#### 3.4 Updated `nginx` Role

Modified `roles/nginx/tasks/main.yaml` to handle different server groups:

```yaml
- name: Deploy server block based on host group
  ansible.builtin.template:
    src: "{{ 'node.conf.j2' if inventory_hostname in groups['webservers'] else 'default.conf.j2' }}"
    dest: /etc/nginx/conf.d/default.conf
    owner: root
    group: root
    mode: '0644'
  notify: restart nginx
```

**Logic:**
- Hosts in `webservers` group → get `node.conf.j2` (reverse proxy)
- Hosts in `servers` group → get `default.conf.j2` (static site)

Created `templates/node.conf.j2`:
```nginx
server {
    listen 80;
    server_name _;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

**NGINX acts as reverse proxy**: Public traffic on port 80 → proxied to Node.js on localhost:3000.

#### 3.5 Created Deployment Playbook

Path: `playbooks/node_service.yaml`

```yaml
---
- name: Deploy Node.js service
  hosts: webservers
  become: true
  
  roles:
    - { role: nodejs, tags: ["nodejs"] }
    - { role: nginx, tags: ["nginx"] }
    - { role: node_app, tags: ["app"] }
```

**Tagged for selective execution:**
- `--tags nodejs` - Install Node.js/PM2 (once)
- `--tags nginx` - Update NGINX config
- `--tags app` - Deploy application code

#### 3.6 Makefile Integration

Updated `../configure_management/Makefile` with new targets:

```makefile
nodejs:
	$(ANSIBLE_PLAYBOOK) $(CURDIR)/ansible/playbooks/node_service.yaml --tags nodejs --limit $(LIMIT) -i $(INV)

deploy:
	$(ANSIBLE_PLAYBOOK) $(CURDIR)/ansible/playbooks/node_service.yaml --tags nginx,app --limit $(LIMIT) -i $(INV)
```

**Why Makefile?**
- Project uses **local Python venv** with pinned Ansible version (not system-wide)
- `make bootstrap` installs Ansible to `.venv/bin/ansible-playbook`
- Makefile ensures correct venv-based Ansible is used
- Avoids "command not found" issues

### Phase 4: Application Development

Created minimal Express application in `node-app/`:

**app.js:**
```javascript
const express = require('express');
const app = express();
const PORT = 3000;
const HOST = '0.0.0.0';  // Listen on all interfaces

app.get('/', (req, res) => {
  res.send('Hello from CI/CD!');
});

app.listen(PORT, HOST, () => {
  console.log(`Server running on http://${HOST}:${PORT}`);
});
```

**Key detail**: `HOST = '0.0.0.0'` allows connections from any network interface (not just localhost).

**package.json:**
```json
{
  "name": "simple-node-service",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": {
    "start": "node app.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

### Phase 5: CI/CD Runner Setup

#### 5.1 Repository Clone

On CI/CD runner as `github-runner` user:
```bash
cd /home/github-runner
git clone https://github.com/alim7007/devops_tasks.git
```

**Note**: This clone is for **manual testing only**. GitHub Actions workflow clones to its own workspace:
`/home/github-runner/actions-runner/_work/devops_tasks/devops_tasks/`

#### 5.2 GitHub Actions Runner Installation

**As root on CI/CD runner:**
```bash
cd /home/github-runner
mkdir actions-runner && cd actions-runner

# Download runner (version 2.311.0)
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz

chown -R github-runner:github-runner /home/github-runner/actions-runner

# Configure as github-runner user (requires token from GitHub repo settings)
sudo -u github-runner ./config.sh --url https://github.com/alim7007/devops_tasks --token <TOKEN>

# Install as systemd service
./svc.sh install github-runner
./svc.sh start
./svc.sh status
```

**Result**: Self-hosted runner appears in GitHub repo → Settings → Actions → Runners.

#### 5.3 Manual Deployment Test

**On CI/CD runner as github-runner:**
```bash
cd ~/devops_tasks/configure_management

# Bootstrap venv and install Ansible
make clean-all
make bootstrap

# Test connectivity
make ping GROUP=webservers

# Install Node.js (one-time)
make nodejs LIMIT=web1

# Deploy application
make deploy LIMIT=web1
```

**Verification:**
```bash
# From CI/CD runner
curl 192.168.22.4:3000        # Direct to Node.js: Hello from CI/CD!
curl 192.168.22.4             # Through NGINX: Hello from CI/CD!

# From anywhere
curl http://64.225.82.128     # Through Load Balancer: Hello from CI/CD!
```

### Phase 6: GitHub Actions Automation

#### 6.1 Workflow Creation

Created `.github/workflows/deploy.yml`:

```yaml
name: Deploy Node.js Service

on:
  push:
    branches: [main]
    paths:
      - 'nodejs_service_deployment/node-app/**'
  workflow_dispatch:

jobs:
  deploy:
    runs-on: self-hosted
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
      
      - name: Update code on web servers
        working-directory: configure_management
        run: |
          make clean-all
          make bootstrap
          make deploy LIMIT=web1
        env:
          ANSIBLE_HOST_KEY_CHECKING: False
```

**Workflow triggers:**
- Automatic: Push to `main` branch with changes in `nodejs_service_deployment/node-app/**`
- Manual: `workflow_dispatch` (Actions tab → Run workflow button)

**Why `make clean-all` and `make bootstrap`?**
- GitHub Actions workspace is ephemeral
- Each run needs fresh Python venv with Ansible installed
- Ensures consistent, reproducible environment
- Alternative would be pre-installing Ansible system-wide (avoided for version control)

**Working directory**: `configure_management` because that's where `Makefile` and Ansible configs live.

**Environment variable**: `ANSIBLE_HOST_KEY_CHECKING: False` skips SSH host key verification (safe in private network).

#### 6.2 Deployment Flow

1. Developer changes `nodejs_service_deployment/node-app/app.js`
2. Commits and pushes to GitHub
3. GitHub detects change, triggers workflow
4. Self-hosted runner (on CI/CD droplet) picks up job
5. Runner executes:
   - Clones repo to `_work/devops_tasks/devops_tasks/`
   - Changes to `configure_management/`
   - Runs `make clean-all` (removes old venv)
   - Runs `make bootstrap` (creates venv, installs Ansible)
   - Runs `make deploy LIMIT=web1` which:
     - Ansible connects via ProxyJump: Runner → Bastion → web1
     - Clones latest code to `/tmp/devops_tasks`
     - Copies `node-app/` to `/opt/node-app/`
     - Runs `npm install`
     - Restarts PM2 process
6. Node.js app reloads with new code
7. NGINX continues reverse proxying to updated app
8. Load balancer serves new version to users

**Deployment time**: ~30-45 seconds (includes venv creation, Ansible execution).

## Current Deployment Status

**Deployed to**: web1 only (`192.168.22.4`)
- Node.js running on port 3000 (PM2-managed)
- NGINX reverse proxy on port 80
- Accessible via load balancer: `http://64.225.82.128`

**Not deployed to**: web2 (`192.168.22.3`)
- Still serves old static site
- Can be deployed by changing `LIMIT=web1` to `LIMIT=webservers` in workflow

**Load balancer behavior:**
- Routes traffic to both web1 (Node.js) and web2 (static site)
- From browser: May return "Hello from CI/CD!" (web1) or `<h1>web-ams3-2</h1>` (web2)
- Inconsistent responses due to round-robin load balancing

**To fix**: Deploy to both servers by updating workflow to `make deploy LIMIT=webservers`.

## Project Structure

```
nodejs_service_deployment/
├── README.md              # This file
├── node-app/              # Express application
│   ├── app.js
│   └── package.json
└── terraform/             # CI/CD runner infrastructure
    ├── cicd.tf
    ├── data.tf
    ├── main.tf
    ├── outputs.tf
    ├── variables.tf
    └── versions.tf

../configure_management/ansible/
├── inventory/
│   └── hosts.ini          # Added [webservers] group
├── roles/
│   ├── nodejs/            # NEW: Node.js/PM2 installation
│   ├── node_app/          # NEW: Application deployment
│   └── nginx/             # UPDATED: Reverse proxy config
├── playbooks/
│   └── node_service.yaml  # NEW: Deployment playbook
└── Makefile               # UPDATED: Added nodejs, deploy targets

../iac_on_digital_ocean/
├── variables.tf           # UPDATED: Added CI/CD IP to allowed_ssh_cidrs
└── servers.tf             # UPDATED: Added port 3000 to firewall (testing only)

.github/workflows/
└── deploy.yml             # NEW: CI/CD automation
```

## Key Technical Decisions

1. **CI/CD inside VPC**: More secure, faster, cheaper than public-only access
2. **ProxyJump instead of agent forwarding**: Works in unattended automation
3. **Separate SSH key for runner**: Security isolation from personal keys
4. **Private IP for bastion access**: VPC-internal communication
5. **Clone-and-move deployment**: Workaround for monorepo structure
6. **Local Ansible venv**: Version control, reproducibility
7. **PM2 for process management**: Auto-restart, logging, production-ready
8. **NGINX reverse proxy**: Security, flexibility, standard practice

## Known Issues & Future Improvements

**Current Issues:**
1. Only web1 deployed (web2 still serves static site)
2. PM2 not configured for automatic reboot persistence
3. No HTTPS/SSL configured
4. Port 3000 exposed in firewall (should be removed in production)

**Future Improvements:**
- Deploy to both web servers for true high availability
- Add PM2 startup script: `pm2 startup systemd`
- Configure Let's Encrypt SSL certificates
- Remove port 3000 from firewall rules
- Add health checks in load balancer configuration
- Implement blue-green or canary deployments
- Add monitoring (PM2 metrics, NGINX logs)

## Testing

```bash
# From CI/CD runner
ssh web1                                    # SSH via ProxyJump
curl 192.168.22.4:3000                     # Direct Node.js
curl 192.168.22.4                          # Through NGINX

# From anywhere
curl http://64.225.82.128                  # Through Load Balancer
```

## Maintenance

**Update application:**
```bash
# Edit node-app/app.js
git commit -am "update: change message"
git push  # Triggers automatic deployment
```

**Manual deployment:**
```bash
ssh github-runner@64.227.71.89
cd ~/devops_tasks/configure_management
make deploy LIMIT=web1
```

**Destroy CI/CD infrastructure:**
```bash
cd nodejs_service_deployment/terraform
terraform destroy  # Removes only CI/CD droplet
```
