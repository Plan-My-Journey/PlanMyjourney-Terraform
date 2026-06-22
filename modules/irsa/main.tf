variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_issuer" {
  description = "OIDC issuer URL without https:// prefix"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for service accounts"
  type        = string
  default     = "production"
}

variable "tags" {
  type = map(string)
}

locals {
  services = {
    ai-service = {
      sa_name  = "ai-service"
      policies = ["bedrock", "secrets"]
    }
    user-service = {
      sa_name  = "user-service"
      policies = ["secrets"]
    }
    travel-service = {
      sa_name  = "travel-service"
      policies = ["secrets"]
    }
    utility-service = {
      sa_name  = "utility-service"
      policies = ["secrets"]
    }
  }
}

data "aws_iam_policy_document" "assume_role" {
  for_each = local.services

  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_issuer}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${each.value.sa_name}"]
    }
  }
}

resource "aws_iam_role" "service" {
  for_each = local.services

  name               = "${var.project_name}-${each.key}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.assume_role[each.key].json

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${each.key}-irsa-${var.environment}"
    Environment = var.environment
    Service     = each.key
  })
}

data "aws_iam_policy_document" "bedrock" {
  statement {
    sid    = "BedrockInvoke"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:Converse",
    ]
    resources = ["arn:aws:bedrock:${var.aws_region}::foundation-model/*"]
  }
}

resource "aws_iam_policy" "bedrock" {
  name   = "${var.project_name}-bedrock-${var.environment}"
  policy = data.aws_iam_policy_document.bedrock.json

  tags = var.tags
}

data "aws_iam_policy_document" "secrets" {
  statement {
    sid    = "SecretsManagerRead"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = ["arn:aws:secretsmanager:${var.aws_region}:${var.account_id}:secret:${var.project_name}/*"]
  }

  statement {
    sid    = "KMSDecrypt"
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]
    resources = ["arn:aws:kms:${var.aws_region}:${var.account_id}:key/*"]
  }
}

resource "aws_iam_policy" "secrets" {
  name   = "${var.project_name}-secrets-read-${var.environment}"
  policy = data.aws_iam_policy_document.secrets.json

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "bedrock" {
  for_each = { for k, v in local.services : k => v if contains(v.policies, "bedrock") }

  role       = aws_iam_role.service[each.key].name
  policy_arn = aws_iam_policy.bedrock.arn
}

resource "aws_iam_role_policy_attachment" "secrets" {
  for_each = { for k, v in local.services : k => v if contains(v.policies, "secrets") }

  role       = aws_iam_role.service[each.key].name
  policy_arn = aws_iam_policy.secrets.arn
}
