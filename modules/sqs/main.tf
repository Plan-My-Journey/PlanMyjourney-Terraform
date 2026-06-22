locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_sqs_queue" "ai_jobs_dlq" {
  name                      = "${local.name_prefix}-ai-jobs-dlq"
  message_retention_seconds = 1209600
  kms_master_key_id         = var.kms_key_arn

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-ai-jobs-dlq"
    Environment = var.environment
    Purpose     = "ai-async-jobs-dlq"
  })
}

resource "aws_sqs_queue" "ai_jobs" {
  name                       = "${local.name_prefix}-ai-jobs"
  visibility_timeout_seconds = 300
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 20
  kms_master_key_id          = var.kms_key_arn

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.ai_jobs_dlq.arn
    maxReceiveCount     = 5
  })

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-ai-jobs"
    Environment = var.environment
    Purpose     = "ai-async-jobs"
  })
}

resource "aws_dynamodb_table" "ai_jobs" {
  name         = "${local.name_prefix}-ai-jobs"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "job_id"

  attribute {
    name = "job_id"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_arn
  }

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-ai-jobs"
    Environment = var.environment
    Purpose     = "ai-async-job-status"
  })
}
