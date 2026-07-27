variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "Availability zone for the public subnet"
  type        = string
  default     = "us-east-1a"
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed to reach SSH/Grafana (your office, VPN, or Tailscale CIDR - never 0.0.0.0/0)"
  type        = list(string)
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair for emergency SSH access"
  type        = string
}

variable "github_org" {
  description = "GitHub org/user owning the app repo, for the OIDC trust policy"
  type        = string
}

variable "github_repo" {
  description = "GitHub repo name for the OIDC trust policy"
  type        = string
  default     = "iot-cold-chain-monitor"
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
  description = "Common tags applied to every resource"
  type        = map(string)
  default = {
    Project   = "iot-cold-chain-monitor"
    ManagedBy = "terraform"
    Env       = "prod"
  }
}
