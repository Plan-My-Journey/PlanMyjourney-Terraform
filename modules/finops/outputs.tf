output "dynamodb_table_name" {
  description = "FinOps DynamoDB table name"
  value       = aws_dynamodb_table.finops_reports.name
}

output "dynamodb_table_arn" {
  description = "FinOps DynamoDB table ARN"
  value       = aws_dynamodb_table.finops_reports.arn
}

output "eventbridge_rule_name" {
  description = "EventBridge rule name for FinOps Lambda schedule"
  value       = aws_cloudwatch_event_rule.finops_schedule.name
}

output "eventbridge_schedule_expression" {
  description = "EventBridge schedule expression for FinOps Lambda"
  value       = aws_cloudwatch_event_rule.finops_schedule.schedule_expression
}

output "sender_email" {
  description = "SES sender email for FinOps reports"
  value       = aws_ses_email_identity.finops_sender.email
}
