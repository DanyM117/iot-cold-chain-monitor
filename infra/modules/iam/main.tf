data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# EC2 instance role: read-only access to this app's SSM parameters + basic
# CloudWatch agent permissions. No secrets are ever embedded in the AMI or
# user_data - the Grafana/InfluxDB compose stack reads its .env from these
# parameters at boot.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_server" {
  name               = "${var.name_prefix}-ec2-server-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "ec2_ssm_read" {
  statement {
    sid       = "ReadAppParameters"
    actions   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"]
    resources = ["arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter${var.ssm_parameter_prefix}/*"]
  }

  statement {
    sid       = "DecryptSecureStringParameters"
    actions   = ["kms:Decrypt"]
    resources = ["arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*"]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.*.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ec2_ssm_read" {
  name   = "${var.name_prefix}-ec2-ssm-read"
  role   = aws_iam_role.ec2_server.id
  policy = data.aws_iam_policy_document.ec2_ssm_read.json
}

resource "aws_iam_instance_profile" "ec2_server" {
  name = "${var.name_prefix}-ec2-server-profile"
  role = aws_iam_role.ec2_server.name
}

# ---------------------------------------------------------------------------
# GitHub Actions OIDC role: lets CI push images to ECR without long-lived
# AWS access keys stored as GitHub secrets.
# ---------------------------------------------------------------------------
data "tls_certificate" "github_oidc" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github_oidc.certificates[0].sha1_fingerprint]
  tags            = var.tags
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions_ecr_push" {
  name               = "${var.name_prefix}-gha-ecr-push"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
  tags               = var.tags
}

data "aws_iam_policy_document" "ecr_push" {
  statement {
    sid       = "AuthToken"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "PushPullThisRepoOnly"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    resources = [var.ecr_repository_arn]
  }
}

resource "aws_iam_role_policy" "github_actions_ecr_push" {
  name   = "${var.name_prefix}-gha-ecr-push"
  role   = aws_iam_role.github_actions_ecr_push.id
  policy = data.aws_iam_policy_document.ecr_push.json
}

# ---------------------------------------------------------------------------
# Pi device ECR reader: Raspberry Pi devices can't assume an OIDC role, so
# they need a long-lived credential - but scoped to read-only pull access on
# this one repository only, nothing else. Rotate this periodically; it's the
# one credential in this stack that can't avoid being long-lived.
# ---------------------------------------------------------------------------
resource "aws_iam_user" "ecr_reader" {
  name = "${var.name_prefix}-pi-ecr-reader"
  tags = var.tags
}

data "aws_iam_policy_document" "ecr_pull_only" {
  statement {
    sid       = "AuthToken"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "PullThisRepoOnly"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = [var.ecr_repository_arn]
  }
}

resource "aws_iam_user_policy" "ecr_pull_only" {
  name   = "${var.name_prefix}-pi-ecr-pull-only"
  user   = aws_iam_user.ecr_reader.name
  policy = data.aws_iam_policy_document.ecr_pull_only.json
}

resource "aws_iam_access_key" "ecr_reader" {
  user = aws_iam_user.ecr_reader.name
}
