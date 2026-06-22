output "ai_jobs_queue_url" {
  description = "Primary SQS queue URL for AI async jobs"
  value       = aws_sqs_queue.ai_jobs.url
}

output "ai_jobs_queue_arn" {
  description = "Primary SQS queue ARN for AI async jobs"
  value       = aws_sqs_queue.ai_jobs.arn
}

output "ai_jobs_dlq_arn" {
  description = "Dead-letter queue ARN for AI async jobs"
  value       = aws_sqs_queue.ai_jobs_dlq.arn
}

output "ai_jobs_table_name" {
  description = "DynamoDB table name for AI job status"
  value       = aws_dynamodb_table.ai_jobs.name
}

output "ai_jobs_table_arn" {
  description = "DynamoDB table ARN for AI job status"
  value       = aws_dynamodb_table.ai_jobs.arn
}
