#!/bin/bash

SSID="$1"
PASSWORD="$2"
PROFILE_NAME="AUTO_$SSID"

function validate_arguments(){
    if [[ ${#SSID} == 0 || ${#PASSWORD} == 0 ]]; then
        echo "Invalid SSID or PASSWORD"
        echo "Use: $0 <SSID> <PASSWORD>"
        return 1
    fi
    echo "Arguments validated"
    return 0
}

function create_net_profile(){
    if ! nmcli connection show | grep -q "$PROFILE_NAME"; then
        echo "Creating $PROFILE_NAME network profile"
        nmcli connection add type wifi ifname "*" con-name "$PROFILE_NAME" ssid "$SSID" > /dev/null
        nmcli connection modify "$PROFILE_NAME" wifi-sec.key-mgmt wpa-psk wifi-sec.psk "$PASSWORD"
        nmcli connection modify "$PROFILE_NAME" connection.autoconnect yes
        nmcli connection modify "$PROFILE_NAME" connection.autoconnect-priority 3
        nmcli connection modify "$PROFILE_NAME" ipv4.ignore-auto-dns yes
        nmcli connection modify "$PROFILE_NAME" ipv4.dns "8.8.8.8,1.1.1.1"
        echo "Network profile created. Bringing connection up..."
        nmcli connection up "$PROFILE_NAME" > /dev/null 2>&1
        echo "Waiting 10 seconds for DHCP IP assignment..."
        sleep 10
        return 0
    fi

    echo "Network profile $PROFILE_NAME already exists"
    echo "Updating password and reconnecting..."
    nmcli connection modify "$PROFILE_NAME" wifi-sec.psk "$PASSWORD"
    nmcli connection modify "$PROFILE_NAME" connection.autoconnect yes
    nmcli connection up "$PROFILE_NAME" > /dev/null 2>&1
    echo "Waiting 10 seconds for reconnection..."
    sleep 10

    return 0
}

if ! validate_arguments; then
    exit 1
fi

if ! create_net_profile; then
    exit 1
fi
