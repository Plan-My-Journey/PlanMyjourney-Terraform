variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "domain_prefix" {
  description = "Cognito hosted UI domain prefix"
  type        = string
}

variable "callback_urls" {
  description = "OAuth callback URLs for the app client"
  type        = list(string)
}

variable "logout_urls" {
  description = "OAuth logout URLs for the app client"
  type        = list(string)
}

variable "frontend_domain" {
  description = "Primary frontend domain for CORS and redirects"
  type        = string
}

variable "tags" {
  type = map(string)
}
