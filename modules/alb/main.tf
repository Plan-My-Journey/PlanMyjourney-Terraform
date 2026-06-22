locals {
  alb_name         = "${var.project_name}-alb-${var.environment}"
  logs_bucket_name = "${var.project_name}-alb-logs-${var.account_id}-${var.region}"
  base_domain      = replace(var.certificate_domain, "api.", "")

  common_tags = merge(var.tags, {
    Module      = "alb"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  })
}

# ---------------------------------------------------------------------------
# ALB Access Logs – S3 Bucket
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "alb_logs" {
  bucket        = local.logs_bucket_name
  force_destroy = false

  tags = merge(local.common_tags, {
    Name    = local.logs_bucket_name
    Purpose = "alb-access-logs"
  })
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "alb-logs-lifecycle"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# ---------------------------------------------------------------------------
# ELB Service Account – used to grant ALB permission to write logs
# ---------------------------------------------------------------------------

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowELBRootAccount"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_elb_service_account.main.arn
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/alb-logs/AWSLogs/${var.account_id}/*"
      },
      {
        Sid    = "AllowDeliveryAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.alb_logs.arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.account_id
          }
        }
      },
      {
        Sid    = "AllowDeliveryPut"
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs.arn}/alb-logs/AWSLogs/${var.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"      = "bucket-owner-full-control"
            "aws:SourceAccount" = var.account_id
          }
        }
      },
      {
        Sid       = "DenyHTTP"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.alb_logs.arn,
          "${aws_s3_bucket.alb_logs.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# ACM Certificate
# ---------------------------------------------------------------------------

resource "aws_acm_certificate" "main" {
  domain_name               = var.certificate_domain
  subject_alternative_names = ["*.${local.base_domain}"]
  validation_method         = "DNS"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-cert-${var.environment}"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ---------------------------------------------------------------------------
# Application Load Balancer
# ---------------------------------------------------------------------------

resource "aws_lb" "main" {
  name                             = local.alb_name
  internal                         = false
  load_balancer_type               = "application"
  security_groups                  = [var.alb_security_group]
  subnets                          = var.public_subnet_ids
  enable_deletion_protection       = false
  enable_cross_zone_load_balancing = true
  ip_address_type                  = "ipv4"

  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "alb-logs"
    enabled = true
  }

  tags = merge(local.common_tags, {
    Name = local.alb_name
  })

  depends_on = [aws_s3_bucket_policy.alb_logs]
}

# ---------------------------------------------------------------------------
# Target Group – nginx ingress controller on EKS (NodePort / ip mode)
# ---------------------------------------------------------------------------

resource "aws_lb_target_group" "frontend" {
  name                          = "${var.project_name}-frontend-tg"
  port                          = 80
  protocol                      = "HTTP"
  vpc_id                        = var.vpc_id
  target_type                   = "ip"
  deregistration_delay          = 30
  load_balancing_algorithm_type = "least_outstanding_requests"

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
    matcher             = "200"
  }

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-frontend-tg"
  })
}

# ---------------------------------------------------------------------------
# HTTP Listener – redirect all traffic to HTTPS
# ---------------------------------------------------------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  tags = merge(local.common_tags, {
    Name = "${local.alb_name}-http-listener"
  })
}

# HTTPS listener and listener rules are commented out until the ACM certificate
# for api.aitravel.com is validated via DNS. To re-enable:
# 1. Add a CNAME record in your DNS for api.aitravel.com
# 2. Wait for ACM to validate the certificate
# 3. Uncomment the resources below and run terraform apply

# resource "aws_lb_listener" "https" { ... }
# resource "aws_lb_listener_rule" "api_services" { ... }
# resource "aws_lb_listener_rule" "health_check" { ... }


# ---------------------------------------------------------------------------
# CloudWatch Alarms
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "alb_target_response_time" {
  alarm_name          = "${local.alb_name}-target-response-time"
  alarm_description   = "ALB target response time exceeds 1 second – possible downstream latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
  ok_actions    = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${local.alb_name}-5xx-errors"
  alarm_description   = "ALB is returning elevated HTTP 5xx error responses from targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
  ok_actions    = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "${local.alb_name}-unhealthy-hosts"
  alarm_description   = "One or more ALB target group hosts are failing health checks"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.frontend.arn_suffix
  }

  alarm_actions = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []
  ok_actions    = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  tags = local.common_tags
}
