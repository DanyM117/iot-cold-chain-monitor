variable "name_prefix" {
  description = "Prefix applied to all EC2 resource names"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the Grafana/InfluxDB server"
  type        = string
  default     = "t3.small"
}

variable "subnet_id" {
  description = "Public subnet ID to launch the instance into"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID to attach to the instance"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name granting SSM parameter read access"
  type        = string
}

variable "key_pair_name" {
  description = "Name of an existing EC2 key pair for emergency SSH access (Tailscale SSH is the normal path)"
  type        = string
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GB"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Common tags applied to all resources in this module"
  type        = map(string)
  default     = {}
}
