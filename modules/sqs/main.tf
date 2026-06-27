locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_sqs_queue" "ai_jobs_dlq" {
  name                      = "${local.name_prefix}-ai-jobs-dlq"
  message_retention_seconds = 1209600
  sqs_managed_sse_enabled   = true

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
  # Aligned to live: SQS-managed SSE (the live queue uses SSE-SQS, not a CMK).
  # Long-polling + DLQ below are intentional additions.
  receive_wait_time_seconds = 20
  sqs_managed_sse_enabled   = true

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.ai_jobs_dlq.arn
    maxReceiveCount     = 5
  })

  tags = merge(var.tags, {
    Name        = "${local.name_prefix}-ai-jobs"
    Environment = var.environment
    Purpose     = "ai-async-jobs"
  })

  lifecycle {
    # The live queue was created out-of-band with a 1 MiB max_message_size that
    # the AWS provider schema cannot express (it caps at 256 KiB). Adopt the live
    # value rather than shrinking a working production queue.
    ignore_changes = [max_message_size]
  }
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
