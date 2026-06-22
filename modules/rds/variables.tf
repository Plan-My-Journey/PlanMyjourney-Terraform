variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g. prod, staging)"
}

variable "instance_class" {
  type        = string
  description = "RDS instance class"
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  type        = number
  description = "Initial allocated storage in GB"
  default     = 50
}

variable "max_allocated_storage" {
  type        = number
  description = "Maximum allocated storage for autoscaling in GB"
  default     = 100
}

variable "db_name" {
  type        = string
  description = "Name of the initial database"
  default     = "ai_travel_prod"
}

variable "db_username" {
  type        = string
  description = "Master username for the RDS instance"
  default     = "aitravel_admin"
}

variable "db_password_secret_arn" {
  type        = string
  description = "ARN of Secrets Manager secret containing DB password"
}

variable "database_subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs for the DB subnet group"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where the RDS instance will be deployed"
}

variable "eks_security_group_id" {
  type        = string
  description = "Security group ID of the EKS cluster/nodes allowed to connect"
}

variable "kms_key_arn" {
  type        = string
  description = "ARN of the KMS key for RDS encryption"
}

variable "backup_retention_days" {
  type        = number
  description = "Number of days to retain automated backups"
  default     = 30
}

variable "tags" {
  type        = map(string)
  description = "Additional resource tags"
  default     = {}
}
