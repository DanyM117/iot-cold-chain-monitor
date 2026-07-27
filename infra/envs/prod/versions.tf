terraform {
  required_version = "~> 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "iot-cold-chain-monitor-tfstate" # create out-of-band before first init, see infra/envs/prod/README.md
    key          = "prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # native S3 locking, Terraform 1.10+
  }
}

provider "aws" {
  region = var.aws_region
}
