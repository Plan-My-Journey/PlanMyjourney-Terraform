locals {
  cloudtrail_bucket_name = "${var.project_name}-cloudtrail-${var.account_id}-${var.aws_region}"
  trail_name             = "${var.project_name}-trail"

  common_tags = merge(var.tags, {
    Module      = "governance"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  })
}

# ---------------------------------------------------------------------------
# CloudTrail S3 Bucket
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "cloudtrail" {
  bucket        = local.cloudtrail_bucket_name
  force_destroy = false

  tags = merge(local.common_tags, {
    Name    = local.cloudtrail_bucket_name
    Purpose = "cloudtrail-audit-logs"
  })
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  rule {
    id     = "cloudtrail-lifecycle"
    status = "Enabled"

    filter {}

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

resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.aws_region}:${var.account_id}:trail/${local.trail_name}"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/AWSLogs/${var.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl"  = "bucket-owner-full-control"
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.aws_region}:${var.account_id}:trail/${local.trail_name}"
          }
        }
      },
      {
        Sid       = "DenyHTTP"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.cloudtrail.arn,
          "${aws_s3_bucket.cloudtrail.arn}/*"
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
# CloudWatch Log Group for CloudTrail
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.project_name}"
  retention_in_days = 30

  tags = merge(local.common_tags, {
    Name = "/aws/cloudtrail/${var.project_name}"
  })
}

# ---------------------------------------------------------------------------
# IAM Role – CloudTrail → CloudWatch Logs
# ---------------------------------------------------------------------------

resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name        = "${var.project_name}-cloudtrail-cw-role-${var.environment}"
  description = "Allows CloudTrail to publish events to CloudWatch Logs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudTrailAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-cloudtrail-cw-role-${var.environment}"
  })
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  name = "${var.project_name}-cloudtrail-cw-policy-${var.environment}"
  role = aws_iam_role.cloudtrail_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCreateLogStream"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# CloudTrail
# ---------------------------------------------------------------------------

resource "aws_cloudtrail" "main" {
  name                          = local.trail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch.arn

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }

  tags = merge(local.common_tags, {
    Name = local.trail_name
  })

  depends_on = [
    aws_s3_bucket_policy.cloudtrail,
    aws_iam_role_policy.cloudtrail_cloudwatch
  ]
}

# ---------------------------------------------------------------------------
# SNS Topic Policy – allow EventBridge to publish to monitoring SNS
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "sns_eventbridge_publish" {
  statement {
    sid    = "AllowEventBridgePublish"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["SNS:Publish"]
    resources = [var.monitoring_sns_topic_arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "eventbridge_publish" {
  arn    = var.monitoring_sns_topic_arn
  policy = data.aws_iam_policy_document.sns_eventbridge_publish.json
}

# ---------------------------------------------------------------------------
# EventBridge Rules & Targets
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "ec2_launch" {
  name        = "${var.project_name}-ec2-launch-${var.environment}"
  description = "Detect EC2 RunInstances API calls via CloudTrail"

  event_pattern = jsonencode({
    source      = ["aws.ec2"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = ["RunInstances"]
    }
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-ec2-launch-${var.environment}"
  })
}

resource "aws_cloudwatch_event_target" "ec2_launch_sns" {
  rule      = aws_cloudwatch_event_rule.ec2_launch.name
  target_id = "ec2LaunchSnsTarget"
  arn       = var.monitoring_sns_topic_arn
}

resource "aws_cloudwatch_event_rule" "rds_changes" {
  name        = "${var.project_name}-rds-changes-${var.environment}"
  description = "Detect RDS create, modify, and delete API calls via CloudTrail"

  event_pattern = jsonencode({
    source      = ["aws.rds"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = [
        "CreateDBInstance",
        "ModifyDBInstance",
        "DeleteDBInstance"
      ]
    }
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-rds-changes-${var.environment}"
  })
}

resource "aws_cloudwatch_event_target" "rds_changes_sns" {
  rule      = aws_cloudwatch_event_rule.rds_changes.name
  target_id = "rdsChangesSnsTarget"
  arn       = var.monitoring_sns_topic_arn
}

resource "aws_cloudwatch_event_rule" "iam_changes" {
  name        = "${var.project_name}-iam-changes-${var.environment}"
  description = "Detect sensitive IAM mutation API calls via CloudTrail"

  event_pattern = jsonencode({
    source      = ["aws.iam"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = [
        "CreateAccessKey",
        "AttachUserPolicy",
        "AttachRolePolicy",
        "CreateUser",
        "DeleteUser"
      ]
    }
  })

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-iam-changes-${var.environment}"
  })
}

resource "aws_cloudwatch_event_target" "iam_changes_sns" {
  rule      = aws_cloudwatch_event_rule.iam_changes.name
  target_id = "iamChangesSnsTarget"
  arn       = var.monitoring_sns_topic_arn
}

# ---------------------------------------------------------------------------
# AWS Config – IAM Service Role
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "config_assume_role" {
  statement {
    sid    = "ConfigAssumeRole"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "config_service" {
  name               = "${var.project_name}-config-role-${var.environment}"
  description        = "IAM role for AWS Config service recorder"
  assume_role_policy = data.aws_iam_policy_document.config_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-config-role-${var.environment}"
  })
}

resource "aws_iam_role_policy_attachment" "config_managed_policy" {
  role       = aws_iam_role.config_service.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# Allow Config to write to the CloudTrail S3 bucket
resource "aws_iam_role_policy" "config_s3_delivery" {
  name = "${var.project_name}-config-s3-delivery-${var.environment}"
  role = aws_iam_role.config_service.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ConfigS3Put"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl"
        ]
        Resource = [
          aws_s3_bucket.cloudtrail.arn,
          "${aws_s3_bucket.cloudtrail.arn}/*"
        ]
      },
      {
        Sid      = "ConfigSNSPublish"
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = var.monitoring_sns_topic_arn
      }
    ]
  })
}

# ---------------------------------------------------------------------------
# AWS Config – Configuration Recorder
# ---------------------------------------------------------------------------

resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_name}-config"
  role_arn = aws_iam_role.config_service.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# ---------------------------------------------------------------------------
# AWS Config – Delivery Channel
# ---------------------------------------------------------------------------

resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_name}-config"
  s3_bucket_name = aws_s3_bucket.cloudtrail.bucket

  snapshot_delivery_properties {
    delivery_frequency = "Six_Hours"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# ---------------------------------------------------------------------------
# AWS Config – Enable the Recorder
# ---------------------------------------------------------------------------

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}
