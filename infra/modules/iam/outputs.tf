output "ec2_instance_profile_name" {
  description = "IAM instance profile name to attach to the EC2 server"
  value       = aws_iam_instance_profile.ec2_server.name
}

output "github_actions_role_arn" {
  description = "ARN of the role GitHub Actions assumes via OIDC to push to ECR"
  value       = aws_iam_role.github_actions_ecr_push.arn
}

output "ecr_reader_access_key_id" {
  description = "Access key ID for the Pi devices' read-only ECR pull user"
  value       = aws_iam_access_key.ecr_reader.id
  sensitive   = true
}

output "ecr_reader_secret_access_key" {
  description = "Secret access key for the Pi devices' read-only ECR pull user - store this directly into SSM, never in tfvars/CI logs"
  value       = aws_iam_access_key.ecr_reader.secret
  sensitive   = true
}
