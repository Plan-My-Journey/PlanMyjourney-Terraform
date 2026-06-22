data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# ECR Repositories
# ---------------------------------------------------------------------------
resource "aws_ecr_repository" "services" {
  for_each = toset(var.repositories)

  name                 = "${var.project_name}/${each.value}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
    kms_key         = var.kms_key_arn
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}/${each.value}"
    Service     = each.value
    Environment = var.environment
  })
}

# ---------------------------------------------------------------------------
# Lifecycle Policies
# ---------------------------------------------------------------------------
resource "aws_ecr_lifecycle_policy" "services" {
  for_each = toset(var.repositories)

  repository = aws_ecr_repository.services[each.value].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep only the last 10 tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "release", "latest"]
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Expire timestamp-tagged images older than 30 days"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["sha-", "build-", "ci-", "20"]
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = 30
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# Repository Policies (deny public / allow authenticated pulls via IAM)
# ---------------------------------------------------------------------------
resource "aws_ecr_repository_policy" "services" {
  for_each = toset(var.repositories)

  repository = aws_ecr_repository.services[each.value].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowAuthenticatedPull"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:DescribeRepositories",
          "ecr:GetRepositoryPolicy",
          "ecr:ListImages",
          "ecr:DescribeImages"
        ]
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = "*"
          }
        }
      },
      {
        Sid       = "DenyPublicAccess"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Condition = {
          StringEquals = {
            "aws:sourceVpc" = ""
          }
          BoolIfExists = {
            "aws:PrincipalIsAWSService" = "false"
          }
        }
      }
    ]
  })
}
