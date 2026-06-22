terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1"
    }
  }
}

data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# KMS Key
# ---------------------------------------------------------------------------
resource "aws_kms_key" "main" {
  description             = "AI-Travel infrastructure encryption key - ${var.environment}"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRootAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowSecretsManagerAccess"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCloudWatchLogsAccess"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.aws_region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:ReEncrypt*"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowEKSAccess"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-kms-${var.environment}"
    Environment = var.environment
  })
}

resource "aws_kms_alias" "main" {
  name          = "alias/${var.project_name}-${var.environment}"
  target_key_id = aws_kms_key.main.key_id
}

# ---------------------------------------------------------------------------
# RDS Master Password
# ---------------------------------------------------------------------------
resource "random_password" "rds_master_password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "rds_master_password" {
  name                    = "${var.project_name}/rds/master-password/${var.environment}"
  description             = "RDS PostgreSQL master password"
  kms_key_id              = aws_kms_key.main.arn
  recovery_window_in_days = 30

  tags = merge(var.tags, {
    Name        = "${var.project_name}-rds-master-password-${var.environment}"
    Environment = var.environment
  })
}

resource "aws_secretsmanager_secret_version" "rds_master_password" {
  secret_id = aws_secretsmanager_secret.rds_master_password.id
  secret_string = jsonencode({
    username = "aitravel_admin"
    password = random_password.rds_master_password.result
  })
}

# ---------------------------------------------------------------------------
# JWT Secret
# ---------------------------------------------------------------------------
resource "random_password" "jwt_secret" {
  length  = 64
  special = false
}

resource "aws_secretsmanager_secret" "jwt_secret" {
  name                    = "${var.project_name}/jwt-secret/${var.environment}"
  description             = "JWT signing secret for authentication tokens"
  kms_key_id              = aws_kms_key.main.arn
  recovery_window_in_days = 30

  tags = merge(var.tags, {
    Name        = "${var.project_name}-jwt-secret-${var.environment}"
    Environment = var.environment
  })
}

resource "aws_secretsmanager_secret_version" "jwt_secret" {
  secret_id     = aws_secretsmanager_secret.jwt_secret.id
  secret_string = random_password.jwt_secret.result
}

# ---------------------------------------------------------------------------
# Bedrock Configuration
# ---------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "bedrock_config" {
  name                    = "${var.project_name}/bedrock-config/${var.environment}"
  description             = "Amazon Bedrock model configuration"
  kms_key_id              = aws_kms_key.main.arn
  recovery_window_in_days = 30

  tags = merge(var.tags, {
    Name        = "${var.project_name}-bedrock-config-${var.environment}"
    Environment = var.environment
  })
}

resource "aws_secretsmanager_secret_version" "bedrock_config" {
  secret_id = aws_secretsmanager_secret.bedrock_config.id
  secret_string = jsonencode({
    model_id   = "amazon.nova-pro-v1:0"
    region     = var.aws_region
    max_tokens = 1024
  })
}

# ---------------------------------------------------------------------------
# GitHub Token  (populated manually after apply)
# ---------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "github_token" {
  name                    = "${var.project_name}/github-token/${var.environment}"
  description             = "GitHub personal access token for CI/CD pipelines - populate manually"
  kms_key_id              = aws_kms_key.main.arn
  recovery_window_in_days = 30

  tags = merge(var.tags, {
    Name        = "${var.project_name}-github-token-${var.environment}"
    Environment = var.environment
  })
}

# ---------------------------------------------------------------------------
# Third-Party API Keys  (placeholder values - must be replaced)
# ---------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "third_party_apis" {
  name                    = "${var.project_name}/third-party-apis/${var.environment}"
  description             = "Geoapify API key for maps, geocoding, routing, and places"
  kms_key_id              = aws_kms_key.main.arn
  recovery_window_in_days = 30

  tags = merge(var.tags, {
    Name        = "${var.project_name}-third-party-apis-${var.environment}"
    Environment = var.environment
  })
}

resource "aws_secretsmanager_secret_version" "third_party_apis_placeholder" {
  secret_id = aws_secretsmanager_secret.third_party_apis.id
  secret_string = jsonencode({
    GEOAPIFY_API_KEY = "REPLACE_ME"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "aws_secretsmanager_secret" "openweather_api_key" {
  name                    = "${var.project_name}/openweather-api-key/${var.environment}"
  description             = "OpenWeather API key for weather forecasts"
  kms_key_id              = aws_kms_key.main.arn
  recovery_window_in_days = 30

  tags = merge(var.tags, {
    Name        = "${var.project_name}-openweather-api-key-${var.environment}"
    Environment = var.environment
  })
}

resource "aws_secretsmanager_secret_version" "openweather_api_key_placeholder" {
  secret_id = aws_secretsmanager_secret.openweather_api_key.id
  secret_string = jsonencode({
    OPENWEATHER_API_KEY = "REPLACE_ME"
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}
