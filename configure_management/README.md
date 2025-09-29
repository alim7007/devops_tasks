- ✅ 12. Configuration Management Task from https://roadmap.sh/projects/configuration-management

Installing Ansible
<!-- sudo apt-add-repository ppa:ansible/ansible -->
sudo apt update
sudo apt install ansible



for passphrase to disturb
# start agent (macOS usually has one already)
eval "$(ssh-agent -s)"
# load your key once per login session (will prompt for passphrase) 
ssh-add ~/.ssh/id_ed25519 
# verify it's loaded
ssh-add -l

and for first time need to login with ssh for fingerprint




ansible-galaxy collection install -r ansible/collections/requirements.yml





playbook notes:
- hosts: all
A play that targets every host from your inventory. You could use a group like servers instead.

still need better explanations
gather_facts: useful for conditionals (e.g., service name differences).
gather_facts: true — lets you branch with when: (e.g., only run apt on Debian).

become: true
Run tasks with sudo/root on the remote hosts. (Your SSH user may be non-root; Ansible will
update_cache: true ≈ apt-get update.

Ansible modules (like apt, user, lineinfile) check current state and only act if needed.


Ansible Galaxy = a public repository of community-maintained roles and collections.

Website: https://galaxy.ansible.com
Example: geerlingguy.nginx role:

- hosts: webservers
  roles:
    - geerlingguy.nginx


That one line will install nginx, configure it, manage the service, etc.
All the details are already written inside the role.

Best practice today = use FQCN (ansible.builtin.systemd).
Reason: avoids ambiguity if you install third-party collections that also have a systemd module.


ansible.builtin.service
if the machine uses systemd, then service ends up calling systemd anyway — but indirectly.


ansible.builtin.systemd:
It calls systemctl commands directly and exposes systemd-only features.

example
- name: Restart nginx with systemd
  ansible.builtin.systemd: or ansible.builtin.service:
    name: nginx
    state: restarted



/etc/sudoers breaks → sudo stops working fully.
visudo edits safely, checks syntax before saving.
Ansible makes temp file, applies your changes.
Runs visudo -cf tempfile to confirm validity.
If OK, replaces file; if not, aborts.


dry-run
 ansible-playbook ansible/playbooks/setup.yaml --check


 requirements/roles.yml (optional Galaxy roles)
---
roles: []


You’re implementing base/nginx/app/ssh yourself, so this can stay empty.
(If later you add third-party roles, pin them here and vendor them.)

# Dry-run roles for server2 only
ansible-playbook ansible/playbooks/setup.yml --limit server2 --check --diff

# Apply roles to server2 only
ansible-playbook ansible/playbooks/setup.yml --limit server2

# Apply only the nginx role on server2
ansible-playbook ansible/playbooks/setup.yml --limit server2 --tags nginx

# Apply only the app role on server2
ansible-playbook ansible/playbooks/setup.yml --limit server2 --tags app



make venv
make bootstrap
source .venv/bin/activate
