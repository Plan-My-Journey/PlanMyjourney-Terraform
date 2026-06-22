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

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch log groups"
  type        = number
  default     = 7
}

variable "kms_key_arn" {
  description = "ARN of the KMS key for encrypting sensitive resources"
  type        = string
}

variable "sns_topic_email" {
  description = "Email address for SNS alert subscriptions"
  type        = string
  default     = "tkpreethi973@gmail.com"
}

variable "enable_rds_alarms" {
  description = "Enable RDS CloudWatch alarms"
  type        = bool
  default     = true
}

variable "enable_alb_alarms" {
  description = "Enable ALB CloudWatch alarms"
  type        = bool
  default     = true
}

variable "rds_instance_id" {
  description = "RDS instance identifier; leave empty to skip RDS alarms"
  type        = string
  default     = ""
}

variable "alb_arn_suffix" {
  description = "ARN suffix of the ALB for CloudWatch metric dimensions; leave empty to skip ALB alarms"
  type        = string
  default     = ""
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the ALB target group for CloudWatch metric dimensions"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
