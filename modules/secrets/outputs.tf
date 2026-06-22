output "kms_key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.main.key_id
}

output "kms_key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.main.arn
}

output "kms_alias_arn" {
  description = "ARN of the KMS key alias"
  value       = aws_kms_alias.main.arn
}

output "rds_password_secret_arn" {
  description = "ARN of the RDS master password secret"
  value       = aws_secretsmanager_secret.rds_master_password.arn
  sensitive   = true
}

output "rds_password_secret_name" {
  description = "Name of the RDS master password secret"
  value       = aws_secretsmanager_secret.rds_master_password.name
}

output "jwt_secret_arn" {
  description = "ARN of the JWT signing secret"
  value       = aws_secretsmanager_secret.jwt_secret.arn
  sensitive   = true
}

output "bedrock_config_secret_arn" {
  description = "ARN of the Bedrock configuration secret"
  value       = aws_secretsmanager_secret.bedrock_config.arn
  sensitive   = true
}

output "github_token_secret_arn" {
  description = "ARN of the GitHub token secret"
  value       = aws_secretsmanager_secret.github_token.arn
  sensitive   = true
}

output "third_party_apis_secret_arn" {
  description = "ARN of the third-party API keys secret"
  value       = aws_secretsmanager_secret.third_party_apis.arn
  sensitive   = true
}
