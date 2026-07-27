variable "name_prefix" {
  description = "Prefix applied to all IAM resource names"
  type        = string
}

variable "ssm_parameter_prefix" {
  description = "SSM Parameter Store path prefix the EC2 role and Pi devices are allowed to read (e.g. /iot-cold-chain-monitor)"
  type        = string
}

variable "github_org" {
  description = "GitHub organization/user that owns the app repo, used to scope the OIDC trust policy"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (org/repo owner already supplied via github_org) allowed to assume the CI role"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the ECR repository the CI role may push to and Pi devices may pull from"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all resources in this module"
  type        = map(string)
  default     = {}
}
