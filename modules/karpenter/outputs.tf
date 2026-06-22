output "controller_role_arn" {
  description = "IAM role ARN for the Karpenter controller service account"
  value       = aws_iam_role.karpenter_controller.arn
}

output "node_role_arn" {
  description = "IAM role ARN for Karpenter-provisioned nodes"
  value       = aws_iam_role.karpenter_node.arn
}

output "node_instance_profile_name" {
  description = "Instance profile for Karpenter-provisioned nodes"
  value       = aws_iam_instance_profile.karpenter_node.name
}

output "interruption_queue_name" {
  description = "SQS queue name for Karpenter spot interruption handling"
  value       = aws_sqs_queue.karpenter_interruption.name
}
