- Static Site Server Task from: https://roadmap.sh/projects/static-site-server

```bash
# add new user
adduser alim
usermod -aG sudo alim
su - alim
````

If you didn’t have a password for root user and want one now:

```bash
sudo passwd root
```

Install and configure Nginx:

```bash
sudo apt update
sudo apt install nginx
sudo ufw app list
sudo ufw allow 'Nginx HTTP'
sudo ufw status
```

If inactive:

```bash
sudo ufw enable
```

If OpenSSH is not showing as allowed in status, then add it:

```bash
sudo ufw allow OpenSSH
```

---

### Manage Nginx service

To stop your web server:

```bash
sudo systemctl stop nginx
```

To start the web server when it is stopped:

```bash
sudo systemctl start nginx
```

To stop and then start the service again:

```bash
sudo systemctl restart nginx
```

If you are only making configuration changes, Nginx can often reload without dropping connections:

```bash
sudo systemctl reload nginx
```

By default, Nginx is configured to start automatically when the server boots.
If this is not what you want, disable it:

```bash
sudo systemctl disable nginx
```

To re-enable the service to start up at boot:

```bash
sudo systemctl enable nginx
```

---

### Setup site directory and permissions

```bash
sudo mkdir -p /var/www/my_domain/html
sudo chown -R $USER:$USER /var/www/my_domain/html
# or
sudo chown -R alim:alim /var/www/my_domain
sudo chmod -R 755 /var/www/my_domain
```

---

### Create Nginx server block

```bash
sudo vim /etc/nginx/sites-available/my_domain
```

Paste in:

```nginx
server {
        listen 80;
        listen [::]:80;

        root /var/www/my_domain/html;
        index index.html;

        server_name _;

        location / {
                try_files $uri $uri/ =404;
        }
}
```

Enable it:

```bash
sudo ln -s /etc/nginx/sites-available/my_domain /etc/nginx/sites-enabled/
```

---

### Notes

* `sites-available/` → storage of all possible configs.
* `sites-enabled/` → only the configs that are currently active.

With symlinks, you can enable/disable a site just by adding/removing the link, without touching the original config.

---

### Hash bucket size config

```bash
sudo nano /etc/nginx/nginx.conf
```

Find:

```nginx
...
http {
    ...
    server_names_hash_bucket_size 64;
    ...
}
...
```

```bash
sudo nginx -t
```

```bash
sudo systemctl reload nginx
```

```bash
 rsync -avz --delete -e "ssh -i ~/.ssh/digital_ocean" ./static_site_server/ alim@188.166.167.157:/var/www/my_domain/
```


Disable stock default site
```bash
sudo rm -f /etc/nginx/sites-enabled/default
```
Bring back
```bash
sudo ln -s /etc/nginx/sites-available/my_domain /etc/nginx/sites-enabled/
```


# inside server
cd ~/.ssh 

ssh-keygen -t rsa -b 4096 -C "github-actions" -f github-actions

cat ~/.ssh/github-actions.pub >> ~/.ssh/authorized_keys

chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh

for no cache
```bash
sudo nano /etc/nginx/sites-available/my_domain
#update
location / {
    add_header Cache-Control "no-cache, no-store, must-revalidate";
    add_header Pragma "no-cache";
    add_header Expires 0;
    try_files $uri $uri/ =404;
}

sudo nginx -t && sudo systemctl reload nginx
```

