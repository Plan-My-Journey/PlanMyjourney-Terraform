variable "project_name" {
  description = "Project name used in resource naming and tagging"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Tags applied to FinOps resources"
  type        = map(string)
  default     = {}
}

variable "dynamodb_table_name" {
  description = "DynamoDB table for FinOps cost reports and recommendations"
  type        = string
  default     = "finops-cost-baselines"
}

variable "report_ttl_days" {
  description = "TTL in days for daily cost report items (DynamoDB ttl attribute)"
  type        = number
  default     = 90
}

variable "kms_key_arn" {
  description = "Optional KMS key ARN for DynamoDB encryption; uses AWS owned key when empty"
  type        = string
  default     = ""
}

variable "lambda_function_name" {
  description = "Existing FinOps Lambda function name (created outside this module)"
  type        = string
  default     = "cost-anomaly-detector-prod"
}

variable "eventbridge_rule_name" {
  description = "EventBridge rule name that triggers the FinOps Lambda"
  type        = string
  default     = "cost-anomaly-detector-prod-daily"
}

variable "schedule_expression" {
  description = "EventBridge schedule for FinOps analysis runs"
  type        = string
  default     = "rate(1 hour)"
}

variable "sender_email" {
  description = "Verified SES sender address for FinOps digest and daily reports"
  type        = string
  default     = "tkp4762@gmail.com"
}
