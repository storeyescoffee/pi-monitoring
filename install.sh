#!/bin/bash

# install the required dependencies
sudo apt update
sudo apt install mosquitto-clients jq -y

# grant execution permission on main.sh
chmod +x main.sh

# schedule the crontab 
CRON_LINE=$(cat cron)
(crontab -l 2>/dev/null | grep -F "$CRON_LINE") >/dev/null 2>&1 || \
(crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
