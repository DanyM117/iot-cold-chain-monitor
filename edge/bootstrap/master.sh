#!/bin/bash

# ==============================================================================
# Master installer: IoT Cold-Chain Monitor Raspberry Pi cluster
# ==============================================================================

# Default variables
HOSTNAME=""
SSID=""
WIFI_PASS=""
CR_NAME=""
GIT_TOKEN=""
TAILSCALE_AUTHKEY=""

function show_help() {
    echo "Usage: sudo $0 -n <hostname> -s <ssid> -p <password> -c <branch_id> -t <github_token> [-k <tailscale_authkey>]"
    echo ""
    echo "Required:"
    echo "  -n  New hostname for the Raspberry Pi (e.g. rasp-clima-01)"
    echo "  -s  Wi-Fi SSID"
    echo "  -p  Wi-Fi password"
    echo "  -c  Branch/site ID (SUCURSAL_ID) used to tag this device's data"
    echo "  -t  GitHub token (PAT) used to register a read-only deploy key"
    echo ""
    echo "Optional:"
    echo "  -k  Tailscale auth key for fully unattended install"
    echo "  -h  Show this help"
    exit 1
}

while getopts "n:s:p:c:t:k:h" opt; do
  case $opt in
    n) HOSTNAME="$OPTARG" ;;
    s) SSID="$OPTARG" ;;
    p) WIFI_PASS="$OPTARG" ;;
    c) CR_NAME="$OPTARG" ;;
    t) GIT_TOKEN="$OPTARG" ;;
    k) TAILSCALE_AUTHKEY="$OPTARG" ;;
    h) show_help ;;
    *) show_help ;;
  esac
done

# 1. Initial validation
if [[ -z "$HOSTNAME" || -z "$SSID" || -z "$WIFI_PASS" || -z "$CR_NAME" || -z "$GIT_TOKEN" ]]; then
    echo "Error: missing required parameters."
    show_help
fi

if [ "$EUID" -ne 0 ]; then
  echo "Error: this master script must be run with sudo."
  exit 1
fi

# 2. Export env vars for the modular scripts. Secrets (InfluxDB token, SMTP
# password, etc.) are intentionally NOT passed here or hardcoded anywhere in
# this repo - device-setup.sh pulls them from AWS SSM Parameter Store at
# provisioning time using the AWS credentials configured on this device.
export GITHUB_TOKEN="$GIT_TOKEN"
export USER_FOR_DOCKER="${SUDO_USER:-$USER}"

if [ -n "$TAILSCALE_AUTHKEY" ]; then
    export TS_AUTHKEY="$TAILSCALE_AUTHKEY"
fi

echo "==================================================="
echo "Starting automated IoT deployment..."
echo "==================================================="

chmod +x ./*.sh

# 3. Sequential module execution
echo -e "\n---> [1/7] Configuring hostname..."
./hostname-setup.sh "$HOSTNAME" || { echo "Critical failure: hostname"; exit 1; }

echo -e "\n---> [2/7] Configuring Wi-Fi network profile..."
./network-profile.sh "$SSID" "$WIFI_PASS" || { echo "Critical failure: network"; exit 1; }

echo -e "\n---> [3/7] Validating internet connectivity..."
./validate_internet.sh || { echo "No internet connection. Aborting."; exit 1; }

echo -e "\n---> [4/7] Installing Docker..."
./docker-install.sh || { echo "Critical failure: Docker install"; exit 1; }

echo -e "\n---> [5/7] Installing Tailscale..."
./tailscale-setup.sh || { echo "Critical failure: Tailscale install"; exit 1; }

echo -e "\n---> [6/7] Configuring network watchdog..."
./watchdog-setup.sh || { echo "Critical failure: watchdog"; exit 1; }

echo -e "\n---> [7/7] Cloning app repo and provisioning device environment..."
./device-setup.sh "$CR_NAME" || { echo "Critical failure: repo/environment setup"; exit 1; }

echo ""
echo "==================================================="
echo "Setup complete!"
echo "==================================================="
echo "A reboot is required to apply the hostname change"
echo "and Docker group membership."
echo ""
read -r -p "Reboot the Raspberry Pi now? (y/N): " REBOOT_CONFIRM
if [[ "$REBOOT_CONFIRM" =~ ^[yY]$ ]]; then
    echo "Rebooting in 3 seconds..."
    sleep 3
    reboot
else
    echo "Remember to run 'sudo reboot' manually."
fi
