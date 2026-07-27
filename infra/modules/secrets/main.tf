# Device secrets (InfluxDB token, SMTP password, recipient list, etc.) live
# only here - as encrypted SSM parameters - never as literals in any script
# or committed file. edge/bootstrap/device-setup.sh reads these at
# provisioning time via an IAM identity scoped to this path prefix.
#
# One resource per named secret (rather than for_each over a map) because
# Terraform disallows using a sensitive value as a for_each key.
locals {
  device_secret_values = {
    influx_url     = var.influx_url
    influx_token   = var.influx_token
    influx_org     = var.influx_org
    influx_bucket  = var.influx_bucket
    email_from     = var.email_from
    email_password = var.email_password
    email_to       = var.email_to
  }
}

resource "aws_ssm_parameter" "influx_url" {
  name  = "${var.parameter_prefix}/influx_url"
  type  = "SecureString"
  value = local.device_secret_values.influx_url
  tags  = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "influx_token" {
  name  = "${var.parameter_prefix}/influx_token"
  type  = "SecureString"
  value = local.device_secret_values.influx_token
  tags  = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "influx_org" {
  name  = "${var.parameter_prefix}/influx_org"
  type  = "SecureString"
  value = local.device_secret_values.influx_org
  tags  = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "influx_bucket" {
  name  = "${var.parameter_prefix}/influx_bucket"
  type  = "SecureString"
  value = local.device_secret_values.influx_bucket
  tags  = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "email_from" {
  name  = "${var.parameter_prefix}/email_from"
  type  = "SecureString"
  value = local.device_secret_values.email_from
  tags  = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "email_password" {
  name  = "${var.parameter_prefix}/email_password"
  type  = "SecureString"
  value = local.device_secret_values.email_password
  tags  = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "email_to" {
  name  = "${var.parameter_prefix}/email_to"
  type  = "SecureString"
  value = local.device_secret_values.email_to
  tags  = var.tags

  lifecycle {
    ignore_changes = [value]
  }
}
