#############################################
# GitHub OIDC Provider + Role for CI/CD
#############################################

locals {
  # Ex.: "org/repo"
  github_repo = var.github_repo
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.enable_github_actions_oidc ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # thumbprint atual padrão (GitHub). Se mudar no futuro, ajuste.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  tags = var.tags
}

data "aws_iam_policy_document" "github_assume_role" {
  count = var.enable_github_actions_oidc ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github[0].arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Permite:
    # - PRs (plan)
    # - push em main (apply)
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${local.github_repo}:pull_request",
        "repo:${local.github_repo}:ref:refs/heads/main"
      ]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  count = var.enable_github_actions_oidc ? 1 : 0

  name               = "${var.project_name}-${var.environment}-gha-oidc"
  assume_role_policy = data.aws_iam_policy_document.github_assume_role[0].json

  tags = var.tags
}

#############################################
# Policy (CI) - "bom o bastante" para entrevista
# (Depois você refina para least-privilege)
#############################################

data "aws_iam_policy_document" "gha_ci_policy" {
  count = var.enable_github_actions_oidc ? 1 : 0

  # Terraform state (S3 + DynamoDB lock)
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts"
    ]
    resources = [
      "arn:aws:s3:::nexus-${data.aws_caller_identity.current.account_id}-terraform-state-${var.environment}",
      "arn:aws:s3:::nexus-${data.aws_caller_identity.current.account_id}-terraform-state-${var.environment}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem",
      "dynamodb:Scan",
      "dynamodb:Query"
    ]
    resources = [
      "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/terraform-locks-${var.environment}-${data.aws_caller_identity.current.account_id}"
    ]
  }

  # EKS / EC2 / IAM / VPC para provisionar cluster + rede (demo)
  statement {
    effect = "Allow"
    actions = [
      "eks:*",
      "ec2:*",
      "iam:*",
      "logs:*",
      "autoscaling:*",
      "elasticloadbalancing:*",
      "kms:DescribeKey",
      "kms:ListKeys",
      "kms:ListAliases",
      "sts:GetCallerIdentity"
    ]
    resources = ["*"]
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_policy" "gha_ci" {
  count = var.enable_github_actions_oidc ? 1 : 0

  name   = "${var.project_name}-${var.environment}-gha-ci"
  policy = data.aws_iam_policy_document.gha_ci_policy[0].json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "gha_ci_attach" {
  count = var.enable_github_actions_oidc ? 1 : 0

  role       = aws_iam_role.github_actions[0].name
  policy_arn = aws_iam_policy.gha_ci[0].arn
}
