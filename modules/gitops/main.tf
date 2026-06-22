# AWS CodeConnections for GitHub — used by EKS Flux capability / Flux bootstrap
resource "aws_codestarconnections_connection" "github" {
  name          = "${var.project_name}-github-${var.environment}"
  provider_type = "GitHub"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-github-connection-${var.environment}"
    Environment = var.environment
  })
}

# IAM role for Flux source-controller (IRSA)
data "aws_iam_policy_document" "flux_assume" {
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
      values   = ["system:serviceaccount:flux-system:source-controller"]
    }
  }
}

resource "aws_iam_role" "flux_source" {
  name               = "${var.project_name}-flux-source-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.flux_assume.json

  tags = merge(var.tags, {
    Name        = "${var.project_name}-flux-source-${var.environment}"
    Environment = var.environment
  })
}

resource "aws_iam_role_policy" "flux_source" {
  name = "${var.project_name}-flux-source-${var.environment}"
  role = aws_iam_role.flux_source.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CodeConnectionsUse"
        Effect = "Allow"
        Action = [
          "codestar-connections:UseConnection",
          "codestar-connections:GetConnection",
        ]
        Resource = aws_codestarconnections_connection.github.arn
      }
    ]
  })
}
