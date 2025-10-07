- ✅ 17. Automated DB Backups Task from https://roadmap.sh/projects/automated-backups

## Features

- 🔄 Automated backups every 12 hours via GitHub Actions
- ☁️ Cloud storage on Backblaze B2 (10GB free tier)
- 💾 Local backup retention (last 14 backups)
- 🔐 Secure backup with compression
- 📦 Easy restore with interactive script

## Architecture
GitHub Actions (Every 12h)
↓
SSH to Server
↓
Run backup.sh
↓
mongodump → tar.gz → Upload to B2
↓
Local + Remote Storage

## Setup

### 1. Prerequisites

- MongoDB running in Docker container
- Backblaze B2 account (free tier)
- AWS CLI installed on server

### 2. Install AWS CLI
```bash
# Remove old version if exists
sudo apt remove awscli -y
sudo apt autoremove -y
sudo rm -f /usr/bin/aws
```

# Install AWS CLI v2
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip
```

# Verify
```bash
aws --version  # Should show: aws-cli/2.x.x
```
3. Configure Backblaze B2
bash# Configure AWS CLI with B2 credentials
```bash
aws configure
```

# Enter:
AWS Access Key ID: <B2_keyID>
AWS Secret Access Key: <B2_applicationKey>
Default region: auto
Default output format: json
4. Create Backup Directory
bashsudo mkdir -p /opt/backups/mongodb
5. Test Backup Manually
bash# Run backup script
sudo /usr/local/bin/mongodb-backup.sh

# Check backup created
ls -lh /opt/backups/mongodb/

# Check uploaded to B2
aws s3 ls s3://my-mongodb-backups/backups/ \
  --endpoint-url https://s3.eu-central-003.backblazeb2.com
Usage
Automatic Backups
Backups run automatically every 12 hours via GitHub Actions.
Schedule: 0 */12 * * * (midnight and noon UTC)
Note: Uses GitHub Actions instead of server cron for better reliability and centralized management.
Manual Backup
bashsudo /usr/local/bin/mongodb-backup.sh
Restore from Backup
bash# Interactive restore
sudo /usr/local/bin/mongodb-restore.sh

# Options:
# 1. List backups on B2
# 2. List local backups  
# 3. Download latest from B2
# 4. Restore from local backup
# 5. Download and restore latest (emergency)
Important: Restore automatically stops the API container to prevent data corruption during restore.

GitHub Actions triggers every 12 hours
Copies latest backup script to server
Runs mongodump inside MongoDB container
Compresses dump to .tar.gz with timestamp
Uploads to Backblaze B2
Keeps last 14 local backups
Cleans up temporary files

Restore Process

Stop API container (prevents writes)
Download backup from B2 (or use local)
Extract tarball
Drop existing database (optional)
Run mongorestore
Start API container
Verify API is responding

Storage
Local: /opt/backups/mongodb/ (last 14 backups)
Remote: Backblaze B2 s3://my-mongodb-backups/backups/
Retention:

Local: 14 backups (~7 days with 2/day)
Remote: All backups (manual cleanup)

Monitoring
Check Backup Status
bash# List local backups
ls -lh /opt/backups/mongodb/

# List B2 backups
```bash
aws s3 ls s3://my-mongodb-backups/backups/ \
  --endpoint-url https://s3.eu-central-003.backblazeb2.com
```

# View GitHub Actions runs
# Go to: https://github.com/YOUR_USER/YOUR_REPO/actions
Verify Backup Integrity
bash# Test extraction
```bash
tar -tzf /opt/backups/mongodb/mongo-todos_*.tar.gz
```

# Test restore to temp database (non-destructive)
```bash
mkdir /tmp/test-restore
tar -xzf /opt/backups/mongodb/mongo-todos_*.tar.gz -C /tmp/test-restore
ls /tmp/test-restore/todos/  # Should show .bson files
rm -rf /tmp/test-restore
Troubleshooting
Backup fails
bash# Check container is running
docker ps | grep todo-mongodb

# Check AWS CLI configured
aws s3 ls --endpoint-url https://s3.eu-central-003.backblazeb2.com

# Check script permissions
ls -l /usr/local/bin/mongodb-backup.sh

# Run manually to see errors
sudo /usr/local/bin/mongodb-backup.sh
Restore fails
bash# Check backup file exists
ls /opt/backups/mongodb/

# Check MongoDB container running
docker ps | grep todo-mongodb

# Check API stopped before restore
docker ps | grep todo-api  # Should NOT show during restore

# View detailed logs
docker logs todo-mongodb
```

GitHub Actions vs Cron
This project uses GitHub Actions instead of server cron:
✅ Centralized management (no SSH to configure)
✅ Runs even if server is down (can alert you)
✅ Version controlled workflow
✅ Easy to modify schedule
✅ Built-in notifications on failure
Traditional cron approach:
bash# This is what you'd do with server cron (not used in this project)
```bash
crontab -e
0 */12 * * * /usr/local/bin/mongodb-backup.sh
```

Security Notes

✅ Backups compressed and stored securely on B2
✅ AWS credentials stored in ~/.aws/credentials (chmod 600)
✅ Scripts require sudo (only root can run)
✅ GitHub secrets used for SSH keys
⚠️ Consider encrypting backups for sensitive data

Cost
Free Tier (Backblaze B2)

QUICK RESTORE COMMAND
# Emergency restore (downloads latest and restores)
sudo /usr/local/bin/mongodb-restore.sh <<< "5"$'\n'"yes"

