- ✅ 18. Bastion Host Task from https://roadmap.sh/projects/bastion-host

## Overview

This adds a second authentication factor after SSH key verification:
1. User connects with SSH key (what you have)
2. User enters 6-digit TOTP code from authenticator app (what you know)

## Prerequisites

- SSH access to bastion: `152.42.135.12`
- Smartphone with authenticator app:
  - Google Authenticator (iOS/Android)
  - Authy (iOS/Android)
  - Microsoft Authenticator (iOS/Android)
  - Any TOTP-compatible app

---

## Installation & Configuration

### Step 1: Install PAM Google Authenticator Module

```bash
# SSH to bastion
ssh -i ~/.ssh/digital_ocean root@152.42.135.12

# Install the package
apt-get update
apt-get install -y libpam-google-authenticator
```

### Step 2: Configure Google Authenticator for Root User

```bash
# Run as root (or any user that needs MFA)
google-authenticator
```

**Interactive Setup - Answer these questions:**

```
Do you want authentication tokens to be time-based? (y/n) 
→ y

# You'll see a QR code and emergency scratch codes
# IMPORTANT: Save the emergency scratch codes in a safe place!
```

**Scan the QR code** with your authenticator app, or manually enter the secret key.

**Continue with prompts:**

```
Do you want me to update your "/root/.google_authenticator" file? (y/n)
→ y

Do you want to disallow multiple uses of the same authentication token? (y/n)
→ y

By default, tokens are good for 30 seconds. Do you want to increase time skew? (y/n)
→ n

Do you want to enable rate-limiting? (y/n)
→ y
```

### Step 3: Configure PAM (Pluggable Authentication Modules)

Edit PAM SSH configuration:

```bash
vim /etc/pam.d/sshd
```

**Add this line at the TOP of the file:**

```
auth required pam_google_authenticator.so
```

**Full example `/etc/pam.d/sshd`:**
```
# PAM configuration for the Secure Shell service

# Added for Google Authenticator MFA
auth required pam_google_authenticator.so

# Standard Un*x authentication.
@include common-auth
@include common-account
@include common-session
@include common-password
```

### Step 4: Configure SSH Daemon

Edit SSH server configuration:

```bash
vim /etc/ssh/sshd_config
```

**Find and modify these lines:**

```
# Enable challenge-response authentication
ChallengeResponseAuthentication yes

# Enable PAM
UsePAM yes

# Keep public key authentication enabled
PubkeyAuthentication yes

# Require both key AND MFA (recommended)
AuthenticationMethods publickey,keyboard-interactive
```

**Important settings explained:**

- `ChallengeResponseAuthentication yes` - Allows SSH to prompt for TOTP code
- `UsePAM yes` - Enables PAM modules (including Google Authenticator)
- `AuthenticationMethods publickey,keyboard-interactive` - Requires BOTH SSH key AND TOTP code

### Step 5: Test Configuration (Important!)

**Before restarting SSH, test the configuration:**

```bash
# Check SSH config syntax
sshd -t

# If no errors, you're good
```

**Keep your current SSH session open** as a safety net!

### Step 6: Restart SSH Service

```bash
systemctl restart sshd
```

### Step 7: Test MFA Connection

**Open a NEW terminal** (keep the old one open as backup):

```bash
ssh -i ~/.ssh/digital_ocean root@152.42.135.12
```

**You should see:**

```
Verification code: 
```

**Enter the 6-digit code from your authenticator app.**

If successful, you're in! If it fails, use your backup session to troubleshoot.

---

## Setting Up MFA for Additional Users

If you have other users (like `github-runner`):

```bash
# Switch to that user
sudo -u github-runner -i

# Run the setup
google-authenticator

# Answer the same questions as above
# Each user gets their own QR code and emergency codes
```

---

## Emergency Access (If You Lose Your Phone)

### Method 1: Emergency Scratch Codes

During setup, you received 5 emergency scratch codes. Each can be used ONCE instead of a TOTP code.

**Save these codes somewhere safe:**
- Password manager
- Encrypted file
- Physical paper in a safe

**Usage:**
```
Verification code: [enter scratch code]
```

After use, that code is invalidated.

### Method 2: Disable MFA Temporarily

If you lose all access and need to recover:

1. **From DigitalOcean console** (web-based terminal):
   - Go to your droplet in DO dashboard
   - Click "Access" → "Launch Droplet Console"
   - Log in as root

2. **Disable MFA temporarily:**
   ```bash
   # Comment out the MFA line in PAM
   sed -i 's/^auth required pam_google_authenticator.so/#auth required pam_google_authenticator.so/' /etc/pam.d/sshd
   
   # Restart SSH
   systemctl restart sshd
   ```

3. **SSH in normally, reconfigure MFA, then re-enable it**

---

## Automating MFA Setup with Ansible

Create an Ansible role to configure MFA automatically.

### Create Role Structure

```bash
cd configure_management/ansible/roles
mkdir -p mfa/tasks
mkdir -p mfa/templates
```

### Role Tasks: `roles/mfa/tasks/main.yaml`

```yaml
---
- name: Install Google Authenticator PAM module
  ansible.builtin.apt:
    name: libpam-google-authenticator
    state: present
    update_cache: yes

- name: Configure PAM for SSH MFA
  ansible.builtin.lineinfile:
    path: /etc/pam.d/sshd
    line: 'auth required pam_google_authenticator.so'
    insertbefore: '^@include common-auth'
    state: present
  notify: restart sshd

- name: Enable ChallengeResponseAuthentication in SSH
  ansible.builtin.lineinfile:
    path: /etc/ssh/sshd_config
    regexp: '^#?ChallengeResponseAuthentication'
    line: 'ChallengeResponseAuthentication yes'
    state: present
  notify: restart sshd

- name: Enable UsePAM in SSH
  ansible.builtin.lineinfile:
    path: /etc/ssh/sshd_config
    regexp: '^#?UsePAM'
    line: 'UsePAM yes'
    state: present
  notify: restart sshd

- name: Set AuthenticationMethods (key + MFA)
  ansible.builtin.lineinfile:
    path: /etc/ssh/sshd_config
    regexp: '^#?AuthenticationMethods'
    line: 'AuthenticationMethods publickey,keyboard-interactive'
    state: present
  notify: restart sshd

- name: Display manual setup instructions
  ansible.builtin.debug:
    msg:
      - "MFA configuration installed on {{ inventory_hostname }}"
      - "IMPORTANT: Each user must now run: google-authenticator"
      - "This is an interactive setup that cannot be fully automated"
      - "Emergency: Remove 'auth required pam_google_authenticator.so' from /etc/pam.d/sshd to disable MFA"
```

### Handler: `roles/mfa/handlers/main.yaml`

```yaml
---
- name: restart sshd
  ansible.builtin.service:
    name: sshd
    state: restarted
```

### Update Playbook

Add MFA role to your bastion playbook:

```yaml
# playbooks/bastion_mfa.yaml
---
- name: Configure MFA on bastion
  hosts: bastion
  become: true
  
  roles:
    - mfa
```

### Run Playbook

```bash
cd configure_management
ansible-playbook ansible/playbooks/bastion_mfa.yaml
```

**After Ansible run, you must still manually:**
```bash
ssh root@152.42.135.12
google-authenticator
# Follow interactive prompts
```

---

## Testing MFA

### Test 1: Verify MFA is Required

```bash
# Try to SSH
ssh root@152.42.135.12

# Expected output:
# Verification code: 
```

Enter your 6-digit TOTP code.

### Test 2: Test Wrong Code

```bash
# Enter incorrect code
Verification code: 000000

# Should reject:
# Permission denied (keyboard-interactive).
```

### Test 3: Test Emergency Code

```bash
# Use one of your scratch codes
Verification code: [scratch code]

# Should work ONCE
# That code is now invalid
```

---

## Troubleshooting

### Problem: "Verification code:" prompt never appears

**Cause:** SSH config doesn't have `ChallengeResponseAuthentication yes`

**Fix:**
```bash
grep "ChallengeResponseAuthentication" /etc/ssh/sshd_config
# Should show: ChallengeResponseAuthentication yes

# If not:
vim /etc/ssh/sshd_config
# Change to yes, then:
systemctl restart sshd
```

### Problem: "Permission denied" even with correct code

**Cause:** Clock skew between server and phone

**Fix:**
```bash
# Check server time
timedatectl

# Sync time
systemctl restart systemd-timesyncd

# Or install NTP
apt-get install -y ntp
```

Your authenticator app uses time-based codes. Server and phone must have synchronized clocks (within 30 seconds).

### Problem: Locked out, no emergency codes

**Solution:** Use DigitalOcean console access:

1. DigitalOcean Dashboard → Your Droplet → Access → Launch Droplet Console
2. Login with root password (if set) or recovery mode
3. Disable MFA:
   ```bash
   vim /etc/pam.d/sshd
   # Comment out: auth required pam_google_authenticator.so
   systemctl restart sshd
   ```

### Problem: Automation (GitHub Actions) fails with MFA enabled

**Issue:** GitHub Actions runner can't enter TOTP codes interactively.

**Solution:** Exclude runner from MFA requirement:

```bash
# Create SSH config match block for automation
vim /etc/ssh/sshd_config
```

Add at the END of the file:

```
# Allow github-runner user to skip MFA (only from VPC)
Match User github-runner Address 192.168.22.0/24
    AuthenticationMethods publickey
```

This allows `github-runner` to authenticate with **only SSH key** when connecting from VPC IPs.

**Better solution:** Use service accounts with restricted keys for automation, keep MFA for human users only.

---

## Security Best Practices

1. **Save emergency codes securely**
   - Print them and store in a safe
   - Or save in encrypted password manager

2. **Use separate QR codes per user**
   - Don't share your QR code/secret key
   - Each user runs `google-authenticator` independently

3. **Monitor failed attempts**
   ```bash
   # Check auth logs
   tail -f /var/log/auth.log | grep 'google_authenticator'
   ```

4. **Rate limiting is enabled by default**
   - Prevents brute-force attacks on TOTP codes
   - 3 attempts per 30 seconds

5. **Backup your `.google_authenticator` file**
   ```bash
   # The file contains your secret key
   cp ~/.google_authenticator ~/.google_authenticator.backup
   ```

6. **Don't disable MFA for convenience**
   - If automation needs access, use service accounts
   - Keep MFA for all human users

---

## Recovery Checklist

If you get locked out:

- [ ] Try all 5 emergency scratch codes
- [ ] Check phone time sync (Settings → Date & Time → Automatic)
- [ ] Check server time: `ssh root@bastion "date"`
- [ ] Use DigitalOcean console access
- [ ] Temporarily disable MFA in `/etc/pam.d/sshd`
- [ ] Reconfigure with `google-authenticator`
- [ ] Re-enable MFA
- [ ] Generate new emergency codes

---

## Summary

**What MFA adds:**
- Second authentication factor (something you have: phone)
- Protection against stolen SSH keys
- Compliance with security standards

**What it doesn't protect against:**
- Compromised authenticator app
- Lost phone with no emergency codes
- Server-side vulnerabilities

**Recommendation:** Implement MFA on bastion host only, not on private servers (they're already behind bastion).
