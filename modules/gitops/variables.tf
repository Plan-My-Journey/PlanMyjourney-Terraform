variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "github_org" {
  type = string
}

variable "gitops_repo" {
  description = "GitOps repository name (planmyjourney-gitops)"
  type        = string
}

variable "gitops_branch" {
  type    = string
  default = "main"
}

variable "gitops_path" {
  description = "Path within gitops repo for Flux to reconcile"
  type        = string
}

variable "cluster_name" {
  type = string
}

variable "oidc_provider_arn" {
  type = string
}

variable "oidc_issuer" {
  type = string
}

variable "tags" {
  type = map(string)
}
