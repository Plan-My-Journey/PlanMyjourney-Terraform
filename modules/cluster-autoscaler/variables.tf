variable "project_name" {
  type        = string
  description = "Project name used in resource naming"
}

variable "environment" {
  type        = string
  description = "Deployment environment (prod, dev)"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name — used to scope ASG tag conditions"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "account_id" {
  type        = string
  description = "AWS account ID"
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the EKS OIDC provider (for IRSA trust policy)"
}

variable "oidc_issuer" {
  type        = string
  description = "OIDC issuer URL without https:// prefix"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources"
}
