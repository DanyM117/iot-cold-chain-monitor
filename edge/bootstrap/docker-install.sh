#!/bin/bash

TARGET_USER=${USER_FOR_DOCKER:-${SUDO_USER:-$USER}}

function download_install_docker(){
    echo "Starting automated Docker installation..."
    if ! curl -fsSL https://get.docker.com -o /tmp/get-docker.sh ; then
        echo "Failed to download the Docker install script"
        return 1
    fi

    chmod 755 /tmp/get-docker.sh
    echo "Running the Docker installer..."
    if ! sh /tmp/get-docker.sh > /dev/null 2>&1; then
        echo "Failed to install the Docker engine"
        return 1
    fi

    echo "Enabling and starting the Docker service..."
    systemctl enable docker
    systemctl start docker
    return 0
}

function adding_user_to_docker(){
    if [ "$TARGET_USER" != "root" ]; then
        echo "Adding user '$TARGET_USER' to the docker group..."
        usermod -aG docker "$TARGET_USER"
        echo "IMPORTANT: group membership takes effect after the next reboot."
        return 0
    fi
    echo "User is already root, no need to add to the docker group."
    return 1
}

if ! download_install_docker; then
    exit 1
fi

echo "Docker installed successfully"
docker --version

rm -f /tmp/get-docker.sh

if ! adding_user_to_docker; then
    echo "Notice: no standard user was added to the docker group."
fi
