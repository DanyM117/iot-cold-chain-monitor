variable "parameter_prefix" {
  description = "SSM Parameter Store path prefix these parameters are created under (e.g. /iot-cold-chain-monitor)"
  type        = string
}

variable "influx_url" {
  description = "InfluxDB URL device apps write to"
  type        = string
  sensitive   = true
}

variable "influx_token" {
  description = "InfluxDB write token"
  type        = string
  sensitive   = true
}

variable "influx_org" {
  description = "InfluxDB org"
  type        = string
  sensitive   = true
}

variable "influx_bucket" {
  description = "InfluxDB bucket"
  type        = string
  sensitive   = true
}

variable "email_from" {
  description = "SMTP sender address for alert emails"
  type        = string
  sensitive   = true
}

variable "email_password" {
  description = "SMTP password for the sender account"
  type        = string
  sensitive   = true
}

variable "email_to" {
  description = "Comma-separated alert recipient list"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Common tags applied to all resources in this module"
  type        = map(string)
  default     = {}
}
