output "server_public_ip" {
  description = "Public IP of the Grafana/InfluxDB EC2 instance"
  value       = module.ec2.public_ip
}

output "ecr_repository_url" {
  description = "URL of the ECR repository for the edge app image"
  value       = aws_ecr_repository.app.repository_url
}

output "github_actions_role_arn" {
  description = "IAM role ARN to configure as AWS_ROLE_ARN in the GitHub Actions workflow"
  value       = module.iam.github_actions_role_arn
}

output "pi_ecr_reader_access_key_id" {
  description = "Access key ID to place in each Pi's .env (AWS_ACCESS_KEY_ID)"
  value       = module.iam.ecr_reader_access_key_id
  sensitive   = true
}

output "pi_ecr_reader_secret_access_key" {
  description = "Secret access key to place in each Pi's .env (AWS_SECRET_ACCESS_KEY) - copy directly into SSM/secure storage, never log it"
  value       = module.iam.ecr_reader_secret_access_key
  sensitive   = true
}
