output "service_role_arns" {
  description = "IRSA role ARNs keyed by service name"
  value       = { for k, v in aws_iam_role.service : k => v.arn }
}
