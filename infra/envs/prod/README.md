# prod environment

## One-time bootstrap (before first `terraform init`)

Create the state bucket (versioning + encryption; native S3 locking needs
Terraform 1.10+ and no separate DynamoDB table):

```bash
aws s3api create-bucket --bucket iot-cold-chain-monitor-tfstate --region us-east-1
aws s3api put-bucket-versioning --bucket iot-cold-chain-monitor-tfstate --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket iot-cold-chain-monitor-tfstate --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
aws s3api put-public-access-block --bucket iot-cold-chain-monitor-tfstate --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
```

Create an EC2 key pair for emergency SSH access (Tailscale SSH is the normal
day-to-day path):

```bash
aws ec2 create-key-pair --key-name iot-cold-chain-monitor-admin --query 'KeyMaterial' --output text > iot-cold-chain-monitor-admin.pem
chmod 400 iot-cold-chain-monitor-admin.pem
```

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars   # fill in real values, this file is gitignored

# Device secrets are passed as env vars, never written to terraform.tfvars:
export TF_VAR_influx_url="..."
export TF_VAR_influx_token="..."
export TF_VAR_influx_org="..."
export TF_VAR_influx_bucket="..."
export TF_VAR_email_from="..."
export TF_VAR_email_password="..."
export TF_VAR_email_to="..."

terraform init
terraform fmt -check
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

Never commit `terraform.tfvars` or put the `TF_VAR_*` secrets in a shell
history file that's checked in - in CI, inject each one as a masked secret.

## CI IAM roles (chicken-and-egg note)

Two separate GitHub OIDC roles are used in CI, and only one of them is
created by this Terraform config:

- **ECR push role** (`AWS_ECR_PUSH_ROLE_ARN`, used by `release-ecr.yml`) -
  created by `module.iam.github_actions_ecr_push` above. Once this stack is
  applied once, grab its ARN from the `github_actions_role_arn` output.
- **Terraform plan role** (`AWS_TERRAFORM_ROLE_ARN`, used by `terraform.yml`)
  is deliberately **not** created here - a role broad enough to plan
  EC2/VPC/IAM/SSM changes can't safely be self-provisioned by the same stack
  it manages. Create it once by hand (or in a separate bootstrap-only state)
  with the same GitHub OIDC trust policy pattern as `module.iam`, scoped to
  this repo, and grant it read/plan-level access to the resource types in
  `infra/modules/*`.
