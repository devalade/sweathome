#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root or with sudo"
  exit 1
fi

HOSTS_FILE="/etc/hosts"

SITES=("linkedin.com" "x.com")

# Backup the original hosts file
cp $HOSTS_FILE $HOSTS_FILE.backup

# Function to block sites
block_sites() {
  for site in "${SITES[@]}"; do
    if ! grep -q "127.0.0.1 $site" $HOSTS_FILE; then
      echo "127.0.0.1 $site" | sudo tee -a $HOSTS_FILE >/dev/null
    fi
  done
}

unblock_sites() {
  for site in "${SITES[@]}"; do
    sudo sed -i "\|127.0.0.1 $site|d" $HOSTS_FILE
  done
}

check_time() {
  current_hour=$(date +%H)
  current_minute=$(date +%M)

  if [[ $current_hour -eq 18 ]] && [[ $current_minute -ge 0 ]] && [[ $current_minute -le 30 ]]; then
    block_sites
  else
    unblock_sites
  fi
}

check_time

# Optional: Add to crontab for continuous checking
# Uncomment and adjust the crontab entry as needed
# (echo "*/5 * * * * /path/to/this/script.sh") | crontab -
