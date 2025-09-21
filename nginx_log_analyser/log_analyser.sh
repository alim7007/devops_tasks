#!/bin/bash

# curl -O https://gist.githubusercontent.com/kamranahmedse/e66c3b9ea89a1a030d3b739eeeef22d0/raw/77fb3ac837a73c4f0206e78a236d885590b7ae35/nginx-access.log

# cat nginx-access.log | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | sort | uniq -c | sort -nr | head -n5
# grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}" nginx-access.log | sort | uniq -c | sort -nr | head -n5
# correct way
# Top 5 IP addresses accessing the server
grep -v '\\x' nginx-access.log | awk -F' - - ' '{ print $1 }' | sort | uniq -c | sort -nr | head -n5 \
| awk '{ $2=substr($0, index($0,$2)); NF=2; print $2 " - " $1 " requests" }'
# 178.128.94.113 - 1087 requests
# 142.93.136.176 - 1087 requests
# 138.68.248.85 - 1087 requests
# 159.89.185.30 - 1086 requests
# 86.134.118.70 - 277 requests

# Top 5 requested URLs pathes
grep -v '\\x' nginx-access.log | awk -F\" '{split($2,r," "); split(r[2],q,"?"); print q[1] }' | sort | uniq -c | sort -nr | head -n5 \
| awk '{ $2=substr($0, index($0,$2)); NF=2; print $2 " - " $1 " requests" }'
# /v1-health - 4560 requests
# / - 283 requests
# /v1-me - 232 requests
# /v1-list-workspaces - 127 requests
# /v1-list-all-tasks/66ffec2665c85844abd1b6a1 - 82 requests

# Top 5 HTTP status codes
grep -v '\\x' nginx-access.log | awk -F\" '{split($3,r," "); print r[1]}' | sort | uniq -c | sort -nr | head -n5 \
| awk '{ $2=substr($0, index($0,$2)); NF=2; print $2 " - " $1 " requests" }'
# 200 - 5740 requests
# 404 - 916 requests
# 304 - 621 requests
# 400 - 198 requests
# 403 - 23 requests

# Top 5 user agents 
 grep -v '\\x' nginx-access.log | awk -F\" '{print $6}' | sort | uniq -c | sort -nr | head -n5 \
| awk '{ $2=substr($0, index($0,$2)); NF=2; print $2 " - " $1 " requests" }'
# DigitalOcean Uptime Probe 0.22.0 (https://digitalocean.com) - 4347 requests
# Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36 - 513 requests
# Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36 - 332 requests
# Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36 - 282 requests
# Custom-AsyncHttpClient - 273 requests