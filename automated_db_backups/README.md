- ✅ 17. Automated DB Backups Task from https://roadmap.sh/projects/automated-backups



# On your server
crontab -e

# Add this line:
0 */12 * * * /path/to/backup-script.sh

but we do with github workflow

apt install awscli
or 
sudo apt remove awscli -y
sudo apt autoremove -y

hash -d aws 2>/dev/null || true
hash -r

sudo rm -f /usr/bin/aws


curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

aws --version
aws-cli/2.31.8 Python/3.13.7 Linux/6.14.0-23-generic exe/x86_64.ubuntu.25



# На всякий случай убрать сломанный старый путь (если есть)
sudo rm -f /usr/bin/aws
