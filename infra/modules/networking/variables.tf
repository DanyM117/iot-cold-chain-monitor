variable "name_prefix" {
  description = "Prefix applied to all networking resource names/tags"
  type        = string
}

variable "vpc_cidr_block" {
  description = "CIDR block for the dedicated VPC"
  type        = string
  default     = "10.20.0.0/24"
}

variable "public_subnet_cidr_block" {
  description = "CIDR block for the single public subnet hosting the EC2 instance"
  type        = string
  default     = "10.20.0.0/26"
}

variable "availability_zone" {
  description = "Availability zone for the public subnet"
  type        = string
}

variable "admin_cidr_blocks" {
  description = "CIDR blocks allowed to reach SSH (22) and Grafana (3000); never leave this as 0.0.0.0/0"
  type        = list(string)

  validation {
    condition     = !contains(var.admin_cidr_blocks, "0.0.0.0/0")
    error_message = "admin_cidr_blocks must not include 0.0.0.0/0 - restrict to your office/VPN/Tailscale CIDR."
  }
}

variable "tags" {
  description = "Common tags applied to all resources in this module"
  type        = map(string)
  default     = {}
}
