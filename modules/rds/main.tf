data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = var.db_password_secret_arn
}

# ---------------------------------------------------------------------------
# Security Group
# ---------------------------------------------------------------------------
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-${var.environment}"
  description = "Security group for RDS PostgreSQL - ${var.environment}"
  vpc_id      = var.vpc_id

  ingress {
    description = "PostgreSQL from EKS nodes"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    # Both the Terraform-managed EKS cluster SG and the EKS auto-managed cluster
    # SG (the one attached to pod/node ENIs) must be allowed — pods connect via
    # the latter. compact() drops the second if not wired (e.g. non-prod).
    security_groups = compact([var.eks_security_group_id, var.eks_cluster_security_group_id])
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-rds-sg-${var.environment}"
    Environment = var.environment
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Subnet Group
# ---------------------------------------------------------------------------
resource "aws_db_subnet_group" "main" {
  name        = "${var.project_name}-db-subnet-group-${var.environment}"
  description = "DB subnet group for ${var.project_name} - ${var.environment}"
  subnet_ids  = var.database_subnet_ids

  tags = merge(var.tags, {
    Name        = "${var.project_name}-db-subnet-group-${var.environment}"
    Environment = var.environment
  })
}

# ---------------------------------------------------------------------------
# Parameter Group
# ---------------------------------------------------------------------------
resource "aws_db_parameter_group" "main" {
  name        = "${var.project_name}-postgres-pg-${var.environment}"
  family      = "postgres15"
  description = "Custom parameter group for ${var.project_name} PostgreSQL 15 - ${var.environment}"

  parameter {
    name         = "max_connections"
    value        = "500"
    apply_method = "pending-reboot"
  }

  parameter {
    name  = "work_mem"
    value = "16384"
  }

  parameter {
    name  = "maintenance_work_mem"
    value = "65536"
  }

  parameter {
    name  = "random_page_cost"
    value = "1.1"
  }

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_disconnections"
    value = "1"
  }

  parameter {
    name  = "log_duration"
    value = "0"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  tags = merge(var.tags, {
    Name        = "${var.project_name}-postgres-pg-${var.environment}"
    Environment = var.environment
  })
}

# ---------------------------------------------------------------------------
# Enhanced Monitoring IAM Role
# ---------------------------------------------------------------------------
resource "aws_iam_role" "rds_monitoring" {
  name        = "${var.project_name}-rds-monitoring-${var.environment}"
  description = "IAM role for RDS enhanced monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRDSMonitoring"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${var.project_name}-rds-monitoring-${var.environment}"
    Environment = var.environment
  })
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# ---------------------------------------------------------------------------
# RDS Instance
# ---------------------------------------------------------------------------
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-postgres-${var.environment}"

  engine         = "postgres"
  engine_version = "15.8"
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = var.kms_key_arn

  db_name  = var.db_name
  username = var.db_username
  password = jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["password"]

  multi_az            = var.multi_az
  publicly_accessible = false

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.main.name

  backup_retention_period = var.backup_retention_days
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  auto_minor_version_upgrade = true
  copy_tags_to_snapshot      = true
  deletion_protection        = true

  skip_final_snapshot       = true
  final_snapshot_identifier = "${var.project_name}-final-snapshot-${var.environment}"

  iam_database_authentication_enabled = true

  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring.arn

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  performance_insights_kms_key_id       = var.kms_key_arn

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = merge(var.tags, {
    Name        = "${var.project_name}-postgres-${var.environment}"
    Environment = var.environment
  })

  depends_on = [aws_iam_role_policy_attachment.rds_monitoring]

  lifecycle {
    # The master password is rotated/managed out-of-band (Secrets Manager +
    # in-cluster k8s secret). Terraform must NOT reset it on every apply, which
    # would risk breaking live DB connectivity. Adopt the live value as-is.
    ignore_changes = [password]
  }
}

