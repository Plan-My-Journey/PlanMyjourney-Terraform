variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"

  validation {
    condition     = contains(["prod", "staging", "dev"], var.environment)
    error_message = "Environment must be one of: prod, staging, dev."
  }
}

variable "project_name" {
  description = "Project name used in resource naming and tagging"
  type        = string
  default     = "ai-travel"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "ai-travel-prod"
}

variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.30"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "node_group_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_group_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 5
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_disk_size" {
  description = "Disk size in GB for EKS worker nodes"
  type        = number
  default     = 50
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB for RDS"
  type        = number
  default     = 50
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage in GB for RDS autoscaling"
  type        = number
  default     = 100
}

variable "db_name" {
  description = "Primary database name"
  type        = string
  default     = "ai_travel_prod"
}

variable "db_username" {
  description = "RDS master username"
  type        = string
  default     = "aitravel_admin"
}

variable "db_backup_retention_days" {
  description = "Number of days to retain RDS backups"
  type        = number
  default     = 30
}

variable "enable_rds_multi_az" {
  description = "Enable RDS Multi-AZ. Default false to match current single-AZ production; enable in a planned maintenance window."
  type        = bool
  default     = false
}

variable "ecr_repositories" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default     = ["frontend", "ai-service", "travel-service", "user-service", "utility-service"]
}

variable "acm_certificate_domain" {
  description = "Domain for ACM certificate"
  type        = string
  default     = "api.aitravel.com"
}

variable "alert_email" {
  description = "Email address for infrastructure alerts"
  type        = string
  default     = "tkpreethi973@gmail.com"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 7
}

variable "github_org" {
  description = "GitHub organization name for OIDC"
  type        = string
  default     = "your-org"
}

variable "github_repo" {
  description = "GitHub repository name for OIDC"
  type        = string
  default     = "ai-travel-planner"
}

variable "finops_dynamodb_table_name" {
  description = "DynamoDB table for FinOps Lambda cost reports"
  type        = string
  default     = "finops-cost-baselines"
}

variable "finops_lambda_function_name" {
  description = "FinOps Lambda function name"
  type        = string
  default     = "cost-anomaly-detector-prod"
}

variable "finops_eventbridge_rule_name" {
  description = "EventBridge rule name for FinOps Lambda schedule"
  type        = string
  default     = "cost-anomaly-detector-prod-daily"
}

variable "finops_schedule_expression" {
  description = "EventBridge schedule for FinOps Lambda (console: rate(1 hour))"
  type        = string
  default     = "rate(1 hour)"
}

variable "finops_sender_email" {
  description = "SES verified sender for FinOps daily/weekly email reports"
  type        = string
  default     = "tkp4762@gmail.com"
}

variable "k8s_namespace" {
  description = "Kubernetes production namespace"
  type        = string
  default     = "production"
}

variable "cognito_domain_prefix" {
  description = "Cognito hosted UI domain prefix"
  type        = string
  default     = "planmyjourney"
}

variable "cognito_callback_urls" {
  description = "OAuth callback URLs"
  type        = list(string)
  default     = ["https://invest-iq.online/callback", "http://localhost:5173/callback"]
}

variable "cognito_logout_urls" {
  description = "OAuth logout URLs"
  type        = list(string)
  default     = ["https://invest-iq.online/", "http://localhost:5173/"]
}

variable "frontend_domain" {
  description = "Primary frontend domain"
  type        = string
  default     = "invest-iq.online"
}

variable "frontend_acm_certificate_arn" {
  description = "ACM certificate ARN (us-east-1) for CloudFront"
  type        = string
  default     = ""
}

variable "github_repos" {
  description = "GitHub repositories allowed for OIDC (org/repo)"
  type        = list(string)
  default = [
    "Plan-My-Journey/planmyjourney-app",
    "Plan-My-Journey/planmyjourney-terraform",
    "Plan-My-Journey/planmyjourney-gitops",
    "Plan-My-Journey/planmyjourney-workflows",
  ]
}

variable "enable_legacy_alb" {
  description = "Create the legacy Terraform ALB (disabled when using KGateway NLB)"
  type        = bool
  default     = false
}
