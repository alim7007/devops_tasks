#!/bin/bash

# Total CPU usage
top -bn1 | grep "Cpu(s)" | \
# sed captures the idle % (92.5 example).
  sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | \ 
# awk subtracts from 100 → gives actual CPU usage %.
  awk '{print 100 - $1"%"}'

# Total memory usage (Free vs Used including percentage)
free -m | awk 'NR==2{printf "Free: %sMB (%.2f%%)\nAvailable: %sMB (%.2f%%)\n", $4, $4/$2*100, $7, $7/$2*100}'

# Total disk usage (Free vs Used including percentage)
df -h / | awk 'NR==2{printf "Used: %s (%s)\nAvailable: %s (%s)\n", $3, $5, $4, 100-$5"%"}'

# Top 5 processes by CPU usage
ps -eo pid,comm,%cpu --sort=-%cpu | head -n 6
# or
ps -eo pid,comm,%cpu --sort=-%cpu --no-headers \
| awk '$2!="ps" && $2!="awk" {printf "%-6s %-20s %s%%\n",$1,$2,$3; if(++n==5) exit}'

# Top 5 processes by memory usage
ps -eo pid,comm,%mem --sort=-%mem | head -n 6
# or
ps -eo pid,comm,%mem --sort=-%mem --no-headers \
| awk '$2!="ps" && $2!="awk" {printf "%-6s %-20s %s%%\n",$1,$2,$3; if(++n==5) exit}'

#add more stats such as os version, uptime, load average, logged in users, failed login attempts

# full info
cat /etc/os-release

uptime