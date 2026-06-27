output "sns_topic_arn" {
  description = "ARN of the SNS topic used for alert notifications"
  value       = aws_sns_topic.alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic used for alert notifications"
  value       = aws_sns_topic.alerts.name
}

output "log_group_names" {
  description = "Map of CloudWatch log group names created by this module"
  value = {
    eks    = aws_cloudwatch_log_group.eks.name
    rds    = aws_cloudwatch_log_group.rds.name
    lambda = aws_cloudwatch_log_group.lambda_finops.name
  }
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard"
  value       = aws_cloudwatch_dashboard.main.dashboard_name
}
