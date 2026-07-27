#!/bin/bash

# --- Configuration ---
GITHUB_ORG="${GITHUB_ORG:-<your-org>}"
GITHUB_REPO="${GITHUB_REPO:-monitor-clima-iot}"
KEY_NAME="iot_deploy_key"
KEY_TITLE="Auto-Generated Deploy Key - IoT Cold-Chain Monitor"

# Run in this script's own directory (works with both `source` and direct exec)
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

# --- Safety check ---
# The token is injected by the master script (exported env var), never
# hardcoded or committed here.
if [ -z "$GITHUB_TOKEN" ]; then
    echo "[-] Error: GITHUB_TOKEN environment variable is not set."
    echo "[-] Pass the token to the master script via its -t flag."
    exit 1
fi

# --- Step 1: Generate the SSH key ---
echo "[*] Generating a new passwordless ED25519 SSH key..."
ssh-keygen -t ed25519 -N "" -C "$KEY_TITLE" -f "./$KEY_NAME" <<< y >/dev/null 2>&1

if [ ! -f "./${KEY_NAME}.pub" ]; then
    echo "[-] Failed to generate SSH key."
    exit 1
fi
echo "[+] Key generated locally at ./$KEY_NAME"

PUB_KEY=$(cat "./${KEY_NAME}.pub")

# --- Step 2: Upload to GitHub via API ---
echo "[*] Uploading public key to repository: $GITHUB_ORG/$GITHUB_REPO..."

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/repos/$GITHUB_ORG/$GITHUB_REPO/keys" \
  -d "{\"title\":\"$KEY_TITLE\",\"key\":\"$PUB_KEY\",\"read_only\":true}")

HTTP_STATUS=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

# --- Step 3: Validate ---
if [ "$HTTP_STATUS" -eq 201 ]; then
    echo "[+] Deploy key added to GitHub successfully."
else
    echo "[-] Failed to add deploy key. HTTP status: $HTTP_STATUS"
    echo "[-] API response: $BODY"
    exit 1
fi
