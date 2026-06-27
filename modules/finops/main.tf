locals {
  common_tags = merge(var.tags, {
    Module      = "finops"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  })
}

# ---------------------------------------------------------------------------
# FinOps report store — keys must match infrastructure/finops-lambda/src/dynamodb_store.py
#   HASH:  execution_date (YYYY-MM-DD or recommendation id)
#   RANGE: metric_type (DAILY | RECOMMENDATION#... | ALERT#...)
# ---------------------------------------------------------------------------

resource "aws_dynamodb_table" "finops_reports" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "execution_date"
  range_key    = "metric_type"

  attribute {
    name = "execution_date"
    type = "S"
  }

  attribute {
    name = "metric_type"
    type = "S"
  }

  # Present in live production; declared here so Terraform adopts (not destroys) it.
  global_secondary_index {
    name            = "metric_type-execution_date-index"
    hash_key        = "metric_type"
    range_key       = "execution_date"
    projection_type = "ALL"
  }

  ttl {
    # Live production table has TTL on "expiration_time" — matched here so
    # Terraform adopts it instead of trying to switch the TTL attribute.
    attribute_name = "expiration_time"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  # Live table uses the DynamoDB default (AWS-owned) encryption — no explicit
  # SSE block, matching production. A CMK can be adopted later as a deliberate change.

  tags = merge(local.common_tags, {
    Name    = var.dynamodb_table_name
    Purpose = "finops-cost-reports"
  })
}

# ---------------------------------------------------------------------------
# EventBridge schedule — matches console rule cost-anomaly-detector-prod-daily
# ---------------------------------------------------------------------------

data "aws_lambda_function" "finops" {
  function_name = var.lambda_function_name
}

resource "aws_cloudwatch_event_rule" "finops_schedule" {
  name                = var.eventbridge_rule_name
  description         = "Triggers FinOps cost analysis Lambda on a fixed schedule"
  schedule_expression = var.schedule_expression

  tags = merge(local.common_tags, {
    Name = var.eventbridge_rule_name
  })
}

resource "aws_cloudwatch_event_target" "finops_lambda" {
  rule      = aws_cloudwatch_event_rule.finops_schedule.name
  target_id = "CostAnomalyLambda"
  arn       = data.aws_lambda_function.finops.arn
}

resource "aws_lambda_permission" "finops_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridgeFinOps"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.finops.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.finops_schedule.arn
}

# ---------------------------------------------------------------------------
# SES sender identity — required for daily/weekly HTML email reports
# ---------------------------------------------------------------------------

resource "aws_ses_email_identity" "finops_sender" {
  email = var.sender_email
}
