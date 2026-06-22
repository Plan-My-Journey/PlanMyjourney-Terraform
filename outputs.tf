# ==============================================================================
# Root Outputs
# ==============================================================================

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "EKS cluster CA certificate"
  value       = module.eks.cluster_ca_certificate
  sensitive   = true
}

output "rds_endpoint" {
  description = "RDS PostgreSQL endpoint"
  value       = module.rds.db_instance_endpoint
  sensitive   = true
}

output "rds_master_username" {
  description = "RDS master username"
  value       = module.rds.db_master_username
}

output "ecr_repository_urls" {
  description = "ECR repository URLs for all services"
  value       = module.ecr.repository_urls
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.alb_dns_name
}

output "sns_topic_arn" {
  description = "SNS alert topic ARN"
  value       = module.monitoring.sns_topic_arn
}

output "kms_key_arn" {
  description = "KMS key ARN for encryption"
  value       = module.secrets.kms_key_arn
  sensitive   = true
}

output "github_oidc_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC"
  value       = module.iam.github_oidc_role_arn
}

output "cloudtrail_s3_bucket" {
  description = "S3 bucket for CloudTrail logs"
  value       = module.governance.cloudtrail_s3_bucket
}

output "finops_dynamodb_table_name" {
  description = "DynamoDB table for FinOps cost reports"
  value       = module.finops.dynamodb_table_name
}

output "finops_lambda_role_name" {
  description = "IAM role name for the FinOps Lambda function"
  value       = module.iam.lambda_execution_role_name
}

output "finops_eventbridge_schedule" {
  description = "EventBridge schedule expression for FinOps Lambda"
  value       = module.finops.eventbridge_schedule_expression
}

output "irsa_role_arns" {
  description = "IRSA role ARNs for microservices"
  value       = module.irsa.service_role_arns
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_web_client_id" {
  description = "Cognito web app client ID"
  value       = module.cognito.web_client_id
}

output "cognito_hosted_ui_domain" {
  description = "Cognito hosted UI URL"
  value       = module.cognito.hosted_ui_domain
}

output "cognito_issuer_url" {
  description = "Cognito OIDC issuer URL"
  value       = module.cognito.issuer_url
}

output "frontend_bucket_name" {
  description = "S3 bucket for React frontend"
  value       = module.frontend_hosting.bucket_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.frontend_hosting.cloudfront_distribution_id
}

output "frontend_url" {
  description = "HTTPS frontend URL"
  value       = module.frontend_hosting.frontend_url
}

output "gitops_connection_arn" {
  description = "CodeConnections ARN for Flux GitOps"
  value       = module.gitops.github_connection_arn
}

output "gitops_repo_url" {
  description = "GitOps repository URL"
  value       = module.gitops.gitops_repo_url
}

output "oidc_provider_arn" {
  description = "EKS OIDC provider ARN"
  value       = module.eks.oidc_provider_arn
}
