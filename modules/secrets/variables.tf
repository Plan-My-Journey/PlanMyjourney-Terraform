variable "aws_region" {
  type        = string
  description = "AWS region where resources are deployed"
}

variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. prod, staging)"
}

variable "tags" {
  type        = map(string)
  description = "Additional resource tags"
  default     = {}
}
