output "role_arn" {
  description = "IAM role ARN for the Cluster Autoscaler service account (IRSA)"
  value       = aws_iam_role.cluster_autoscaler.arn
}

output "role_name" {
  description = "IAM role name for the Cluster Autoscaler"
  value       = aws_iam_role.cluster_autoscaler.name
}

output "policy_arn" {
  description = "IAM policy ARN attached to the Cluster Autoscaler role"
  value       = aws_iam_policy.cluster_autoscaler.arn
}
