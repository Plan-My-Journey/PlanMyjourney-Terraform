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
  description = "Primary Kubernetes namespace for service accounts"
  type        = string
  default     = "production"
}

variable "additional_namespaces" {
  description = "Additional Kubernetes namespaces allowed to assume IRSA roles"
  type        = list(string)
  default     = ["prod", "dev"]
}

variable "sqs_queue_arn" {
  description = "SQS queue ARN for AI async jobs"
  type        = string
  default     = ""
}

variable "jobs_table_arn" {
  description = "DynamoDB table ARN for AI job status"
  type        = string
  default     = ""
}

variable "tags" {
  type = map(string)
}

locals {
  services = {
    ai-service = {
      sa_name  = "ai-service"
      policies = ["bedrock", "secrets", "sqs_publish", "jobs_store"]
    }
    ai-worker = {
      sa_name  = "ai-worker"
      policies = ["bedrock", "secrets", "sqs_consume", "jobs_store"]
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
      values = flatten([
        for ns in distinct(concat([var.namespace], var.additional_namespaces)) : [
          for svc in local.services : "system:serviceaccount:${ns}:${svc.value.sa_name}"
        ]
      ])
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

data "aws_iam_policy_document" "sqs_publish" {
  statement {
    sid    = "SQSSend"
    effect = "Allow"
    actions = [
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes",
      "sqs:SendMessage",
    ]
    resources = [var.sqs_queue_arn]
  }
}

resource "aws_iam_policy" "sqs_publish" {
  count  = var.sqs_queue_arn != "" ? 1 : 0
  name   = "${var.project_name}-sqs-publish-${var.environment}"
  policy = data.aws_iam_policy_document.sqs_publish.json
  tags   = var.tags
}

data "aws_iam_policy_document" "sqs_consume" {
  statement {
    sid    = "SQSConsume"
    effect = "Allow"
    actions = [
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:ChangeMessageVisibility",
    ]
    resources = [var.sqs_queue_arn]
  }
}

resource "aws_iam_policy" "sqs_consume" {
  count  = var.sqs_queue_arn != "" ? 1 : 0
  name   = "${var.project_name}-sqs-consume-${var.environment}"
  policy = data.aws_iam_policy_document.sqs_consume.json
  tags   = var.tags
}

data "aws_iam_policy_document" "jobs_store" {
  statement {
    sid    = "JobsTableAccess"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
    ]
    resources = [
      var.jobs_table_arn,
      "${var.jobs_table_arn}/index/*",
    ]
  }
}

resource "aws_iam_policy" "jobs_store" {
  count  = var.jobs_table_arn != "" ? 1 : 0
  name   = "${var.project_name}-jobs-store-${var.environment}"
  policy = data.aws_iam_policy_document.jobs_store.json
  tags   = var.tags
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

resource "aws_iam_role_policy_attachment" "sqs_publish" {
  for_each = var.sqs_queue_arn != "" ? { for k, v in local.services : k => v if contains(v.policies, "sqs_publish") } : {}

  role       = aws_iam_role.service[each.key].name
  policy_arn = aws_iam_policy.sqs_publish[0].arn
}

resource "aws_iam_role_policy_attachment" "sqs_consume" {
  for_each = var.sqs_queue_arn != "" ? { for k, v in local.services : k => v if contains(v.policies, "sqs_consume") } : {}

  role       = aws_iam_role.service[each.key].name
  policy_arn = aws_iam_policy.sqs_consume[0].arn
}

resource "aws_iam_role_policy_attachment" "jobs_store" {
  for_each = var.jobs_table_arn != "" ? { for k, v in local.services : k => v if contains(v.policies, "jobs_store") } : {}

  role       = aws_iam_role.service[each.key].name
  policy_arn = aws_iam_policy.jobs_store[0].arn
}
