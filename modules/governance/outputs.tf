output "cloudtrail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = aws_cloudtrail.main.arn
}

output "cloudtrail_s3_bucket" {
  description = "Name of the S3 bucket used for CloudTrail log storage"
  value       = aws_s3_bucket.cloudtrail.bucket
}

output "cloudtrail_log_group_name" {
  description = "Name of the CloudWatch Log Group for CloudTrail events"
  value       = aws_cloudwatch_log_group.cloudtrail.name
}

output "eventbridge_rule_arns" {
  description = "Map of EventBridge rule ARNs for governance events"
  value = {
    ec2_launch  = aws_cloudwatch_event_rule.ec2_launch.arn
    rds_changes = aws_cloudwatch_event_rule.rds_changes.arn
    iam_changes = aws_cloudwatch_event_rule.iam_changes.arn
  }
}

output "config_recorder_name" {
  description = "Name of the AWS Config configuration recorder"
  value       = aws_config_configuration_recorder.main.name
}

output "cloudtrail_iam_role_arn" {
  description = "ARN of the IAM role used by CloudTrail to write to CloudWatch Logs"
  value       = aws_iam_role.cloudtrail_cloudwatch.arn
}
