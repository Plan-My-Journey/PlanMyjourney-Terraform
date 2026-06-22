variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "aws_region" {
  description = "AWS region where resources are deployed"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encrypting CloudTrail logs and S3 bucket objects"
  type        = string
}

variable "monitoring_sns_topic_arn" {
  description = "ARN of the SNS topic used by the monitoring module for alert notifications"
  type        = string
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
