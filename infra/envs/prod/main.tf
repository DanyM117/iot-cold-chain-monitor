locals {
  name_prefix          = "iot-cold-chain-monitor"
  ssm_parameter_prefix = "/iot-cold-chain-monitor"
}

resource "aws_ecr_repository" "app" {
  name                 = local.name_prefix
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

module "networking" {
  source = "../../modules/networking"

  name_prefix       = local.name_prefix
  availability_zone = var.availability_zone
  admin_cidr_blocks = var.admin_cidr_blocks
  tags              = var.tags
}

module "iam" {
  source = "../../modules/iam"

  name_prefix          = local.name_prefix
  ssm_parameter_prefix = local.ssm_parameter_prefix
  github_org           = var.github_org
  github_repo          = var.github_repo
  ecr_repository_arn   = aws_ecr_repository.app.arn
  tags                 = var.tags
}

module "secrets" {
  source = "../../modules/secrets"

  parameter_prefix = local.ssm_parameter_prefix
  influx_url       = var.influx_url
  influx_token     = var.influx_token
  influx_org       = var.influx_org
  influx_bucket    = var.influx_bucket
  email_from       = var.email_from
  email_password   = var.email_password
  email_to         = var.email_to
  tags             = var.tags
}

module "ec2" {
  source = "../../modules/ec2"

  name_prefix               = local.name_prefix
  subnet_id                 = module.networking.public_subnet_id
  security_group_id         = module.networking.server_security_group_id
  iam_instance_profile_name = module.iam.ec2_instance_profile_name
  key_pair_name             = var.key_pair_name
  tags                      = var.tags
}
