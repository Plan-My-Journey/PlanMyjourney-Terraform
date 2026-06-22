variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. prod, staging)"
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "aws_region" {
  type        = string
  description = "AWS region where resources are deployed"
}

variable "account_id" {
  type        = string
  description = "AWS account ID"
}

variable "github_org" {
  type        = string
  description = "GitHub organisation name for OIDC trust"
  default     = "your-org"
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name for OIDC trust"
  default     = "ai-travel-planner"
}

variable "github_repos" {
  type        = list(string)
  description = "GitHub org/repo paths allowed for OIDC trust"
  default     = []
}

variable "tags" {
  type        = map(string)
  description = "Additional resource tags"
  default     = {}
}
