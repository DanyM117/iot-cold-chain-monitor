#!/bin/bash

# Provisions this Raspberry Pi with the monitor-clima-iot app and its
# configuration.
#
# Secrets are never hardcoded in this script or committed to git. They are
# fetched at provisioning time from AWS SSM Parameter Store (SecureString),
# using an IAM identity scoped to read-only access under the
# /iot-cold-chain-monitor/* parameter path (see infra/modules/iam). This
# requires the AWS CLI to already be configured on the device (e.g. via
# `aws configure` with a short-lived enrollment credential, or an IoT-role
# equivalent) before running this script.

CR_NAME="$1"
THERMAL_REPO="${THERMAL_REPO_URL:-https://github.com/<your-org>/monitor-clima-iot.git}"
AWS_REGION="${AWS_REGION:-us-east-1}"
SSM_PREFIX="${SSM_PREFIX:-/iot-cold-chain-monitor}"

TARGET_USER=${USER_FOR_DOCKER:-${SUDO_USER:-$USER}}
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)

function validate_arguments(){
    if [[ ${#CR_NAME} == 0 ]]; then
        echo "Invalid branch/site ID"
        echo "Use: ./device-setup.sh <CR_NAME>"
        return 1
    fi
    return 0
}

function install_deps_and_hardware(){
    echo "Installing dependencies (git, awscli)..."
    apt-get update -y > /dev/null
    apt-get install -y git awscli > /dev/null

    echo "Enabling hardware interfaces (I2C and 1-Wire)..."
    raspi-config nonint do_i2c 0
    raspi-config nonint do_onewire 0
    return 0
}

function clone_repo(){
    echo "Cloning monitor-clima-iot into $TARGET_HOME"
    if ! git clone "$THERMAL_REPO" "$TARGET_HOME/monitor-clima-iot"; then
        echo "Failed to clone app repo"
        return 1
    fi
    return 0
}

# Fetches a parameter from SSM. Fails loudly rather than silently falling
# back to an empty/default secret.
function ssm_get(){
    local name="$1"
    local decrypt="$2"
    if [ "$decrypt" = "true" ]; then
        aws ssm get-parameter --name "$SSM_PREFIX/$name" --with-decryption \
            --region "$AWS_REGION" --query "Parameter.Value" --output text
    else
        aws ssm get-parameter --name "$SSM_PREFIX/$name" \
            --region "$AWS_REGION" --query "Parameter.Value" --output text
    fi
}

function write_env(){
    echo "Fetching device configuration from SSM Parameter Store ($SSM_PREFIX)..."

    local influx_url influx_token influx_org influx_bucket
    local email_from email_pass email_to

    influx_url=$(ssm_get "influx_url" false) || return 1
    influx_token=$(ssm_get "influx_token" true) || return 1
    influx_org=$(ssm_get "influx_org" false) || return 1
    influx_bucket=$(ssm_get "influx_bucket" false) || return 1
    email_from=$(ssm_get "email_from" false) || return 1
    email_pass=$(ssm_get "email_password" true) || return 1
    email_to=$(ssm_get "email_to" false) || return 1

    cat << EOF > "$TARGET_HOME/monitor-clima-iot/.env"
INFLUX_URL=$influx_url
INFLUX_TOKEN=$influx_token
INFLUX_ORG=$influx_org
INFLUX_BUCKET=$influx_bucket
SUCURSAL_ID=$CR_NAME
EMAIL_REMITENTE=$email_from
EMAIL_PASSWORD=$email_pass
EMAIL_DESTINO=$email_to
EOF
    chmod 600 "$TARGET_HOME/monitor-clima-iot/.env"
    return 0
}

function repo-setup(){
    if ! write_env; then
        echo "Failed to fetch device configuration from SSM"
        return 1
    fi

    chmod 755 "$TARGET_HOME/monitor-clima-iot/dupdate.sh"
    source ./deploy-key-setup.sh

    mv "./$KEY_NAME" "$TARGET_HOME/monitor-clima-iot/$KEY_NAME"
    mv "./${KEY_NAME}.pub" "$TARGET_HOME/monitor-clima-iot/$KEY_NAME.pub"

    if ! sed -i '/"credsStore"/d' "$TARGET_HOME/.docker/config.json" 2>/dev/null; then
        echo "No credsStore entry to remove (or file does not exist yet)"
    fi

    "$TARGET_HOME/monitor-clima-iot/dupdate.sh"

    chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/monitor-clima-iot"

    return 0
}

if ! validate_arguments; then
    exit 1
fi

if ! install_deps_and_hardware; then
    exit 1
fi

if ! clone_repo; then
    exit 1
fi

if ! repo-setup; then
    exit 1
fi
