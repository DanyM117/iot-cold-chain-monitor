#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "Error: please run this script with sudo."
  exit 1
fi

if [ -z "$1" ]; then
  echo "Usage: $0 <new-hostname>"
  echo "Example: sudo $0 rasp100-dev"
  exit 1
fi

NEW_HOSTNAME=$1

if [[ ! "$NEW_HOSTNAME" =~ ^[a-zA-Z0-9][-a-zA-Z0-9]*[a-zA-Z0-9]$|^[a-zA-Z0-9]$ ]]; then
  echo "Error: '$NEW_HOSTNAME' is not a valid hostname."
  echo "Only letters, numbers and hyphens are allowed. No underscores."
  exit 1
fi

echo "Changing hostname to '$NEW_HOSTNAME'..."

hostnamectl set-hostname "$NEW_HOSTNAME"

if grep -q "preserve_hostname: false" /etc/cloud/cloud.cfg; then
  sed -i 's/^preserve_hostname:[[:space:]]*false/preserve_hostname: true/' /etc/cloud/cloud.cfg
else
  echo "No cloud.cfg found, or no preserve_hostname setting present"
fi

if grep -q "^127\.0\.1\.1" /etc/hosts; then
  sed -i "s/^127\.0\.1\.1.*/127.0.1.1 $NEW_HOSTNAME/" /etc/hosts
else
  sed -i "/^127\.0\.0\.1 localhost/a 127.0.1.1 $NEW_HOSTNAME" /etc/hosts
fi

echo "Done! Hostname updated in the system and in /etc/hosts."
echo "Current hostname: $(hostname)"
echo "Note: a reboot (sudo reboot) is recommended to apply this to all services."
