locals {
  common_tags = merge(var.tags, {
    Module      = "monitoring"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  })
}

# ---------------------------------------------------------------------------
# SNS Topic & Subscription
# ---------------------------------------------------------------------------

resource "aws_sns_topic" "alerts" {
  name              = "${var.project_name}-alerts-${var.environment}"
  kms_master_key_id = "alias/aws/sns"

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-alerts-${var.environment}"
  })
}

resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.sns_topic_email
}

# ---------------------------------------------------------------------------
# CloudWatch Log Groups
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.project_name}-prod"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(local.common_tags, {
    Name = "/aws/eks/${var.project_name}-prod"
  })
}

resource "aws_cloudwatch_log_group" "rds" {
  name              = "/aws/rds/${var.project_name}-${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(local.common_tags, {
    Name = "/aws/rds/${var.project_name}-${var.environment}"
  })
}

resource "aws_cloudwatch_log_group" "lambda_finops" {
  name              = "/aws/lambda/${var.project_name}-finops-${var.environment}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_arn

  tags = merge(local.common_tags, {
    Name = "/aws/lambda/${var.project_name}-finops-${var.environment}"
  })
}

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.project_name}"
  retention_in_days = 30
  kms_key_id        = var.kms_key_arn

  tags = merge(local.common_tags, {
    Name = "/aws/cloudtrail/${var.project_name}"
  })
}

# ---------------------------------------------------------------------------
# RDS CloudWatch Alarms (conditional)
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  count = var.enable_rds_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-rds-cpu-high-${var.environment}"
  alarm_description   = "RDS CPU utilization exceeds 80% – consider vertical scaling or query optimization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "rds_connections_high" {
  count = var.enable_rds_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-rds-connections-high-${var.environment}"
  alarm_description   = "RDS connection count exceeds 400 – risk of connection exhaustion"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 400
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "rds_storage_low" {
  count = var.enable_rds_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-rds-storage-low-${var.environment}"
  alarm_description   = "RDS free storage space is below 10 GB – provision additional storage soon"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 10737418240 # 10 GB in bytes
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "rds_replica_lag" {
  count = var.enable_rds_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-rds-replica-lag-${var.environment}"
  alarm_description   = "RDS replica lag exceeds 1 second – read replica may be falling behind"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReplicaLag"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# ALB CloudWatch Alarms (conditional)
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "alb_response_time_high" {
  count = var.enable_alb_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-alb-response-time-high-${var.environment}"
  alarm_description   = "ALB average target response time exceeds 1 second"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  count = var.enable_alb_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-alb-5xx-errors-${var.environment}"
  alarm_description   = "ALB is returning elevated HTTP 5xx target error responses"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  count = var.enable_alb_alarms ? 1 : 0

  alarm_name          = "${var.project_name}-alb-unhealthy-hosts-${var.environment}"
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
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# CloudWatch Dashboard
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-overview"

  dashboard_body = jsonencode({
    widgets = [
      # ---- RDS CPU Utilization ----
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "RDS CPU Utilization (%)"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Average"
          period = 300
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_id != "" ? var.rds_instance_id : "N/A"]
          ]
          yAxis = {
            left = { min = 0, max = 100 }
          }
          annotations = {
            horizontal = [{ value = 80, label = "Alarm threshold", color = "#ff6961" }]
          }
        }
      },
      # ---- RDS Database Connections ----
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "RDS Database Connections"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Average"
          period = 300
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", var.rds_instance_id != "" ? var.rds_instance_id : "N/A"]
          ]
          annotations = {
            horizontal = [{ value = 400, label = "Alarm threshold", color = "#ff6961" }]
          }
        }
      },
      # ---- RDS Free Storage ----
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 6
        properties = {
          title  = "RDS Free Storage Space (bytes)"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Average"
          period = 300
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", var.rds_instance_id != "" ? var.rds_instance_id : "N/A"]
          ]
          annotations = {
            horizontal = [{ value = 10737418240, label = "10 GB threshold", color = "#ff6961" }]
          }
        }
      },
      # ---- ALB Target Response Time ----
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "ALB Target Response Time (s)"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Average"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix != "" ? var.alb_arn_suffix : "N/A"]
          ]
          annotations = {
            horizontal = [{ value = 1, label = "1s threshold", color = "#ff6961" }]
          }
        }
      },
      # ---- ALB HTTP 5xx Errors ----
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "ALB HTTP 5xx Error Count"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "HTTPCode_Target_5XX_Count", "LoadBalancer", var.alb_arn_suffix != "" ? var.alb_arn_suffix : "N/A"],
            ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arn_suffix != "" ? var.alb_arn_suffix : "N/A"]
          ]
          annotations = {
            horizontal = [{ value = 5, label = "Alarm threshold", color = "#ff6961" }]
          }
        }
      },
      # ---- ALB Request Count ----
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6
        properties = {
          title  = "ALB Request Count"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Sum"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix != "" ? var.alb_arn_suffix : "N/A"]
          ]
        }
      },
      # ---- ALB Healthy vs Unhealthy Host Count ----
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "ALB Healthy / Unhealthy Host Count"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Average"
          period = 60
          metrics = [
            ["AWS/ApplicationELB", "HealthyHostCount", "LoadBalancer", var.alb_arn_suffix != "" ? var.alb_arn_suffix : "N/A", "TargetGroup", var.target_group_arn_suffix != "" ? var.target_group_arn_suffix : "N/A", { color = "#2ca02c", label = "Healthy" }],
            ["AWS/ApplicationELB", "UnHealthyHostCount", "LoadBalancer", var.alb_arn_suffix != "" ? var.alb_arn_suffix : "N/A", "TargetGroup", var.target_group_arn_suffix != "" ? var.target_group_arn_suffix : "N/A", { color = "#d62728", label = "Unhealthy" }]
          ]
        }
      },
      # ---- RDS Replica Lag ----
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "RDS Replica Lag (s)"
          region = var.aws_region
          view   = "timeSeries"
          stat   = "Average"
          period = 300
          metrics = [
            ["AWS/RDS", "ReplicaLag", "DBInstanceIdentifier", var.rds_instance_id != "" ? var.rds_instance_id : "N/A"]
          ]
          annotations = {
            horizontal = [{ value = 1, label = "1s threshold", color = "#ff6961" }]
          }
        }
      }
    ]
  })
}
