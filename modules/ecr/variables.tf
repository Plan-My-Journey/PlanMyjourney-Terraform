variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. prod, staging)"
}

variable "repositories" {
  type        = list(string)
  description = "List of ECR repository names to create"
  default     = ["frontend", "ai-service", "travel-service", "user-service", "utility-service"]
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the KMS key for ECR encryption"
}

variable "tags" {
  type        = map(string)
  description = "Additional resource tags"
  default     = {}
}
