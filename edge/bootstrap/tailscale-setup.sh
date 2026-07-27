#!/bin/bash

set -e

echo "==================================================="
echo "  Tailscale Automated Installer"
echo "  for Raspberry Pi (Raspberry Pi OS / Debian)"
echo "==================================================="
echo ""

echo "[1/4] Updating system repositories..."
sudo apt-get update -y > /dev/null

echo ""
echo "[2/4] Downloading and installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh > /dev/null

echo ""
echo "[3/4] Ensuring the tailscaled service is active..."
sudo systemctl enable --now tailscaled

echo ""
if [ -n "$TS_AUTHKEY" ]; then
    echo "[4/4] Authenticating Tailscale with an auth key (unattended)..."
    sudo tailscale up --authkey="${TS_AUTHKEY}"
    echo "Device successfully joined the tailnet."
else
    echo "[4/4] No auth key detected. Manual authentication required:"
    sudo tailscale up
fi
