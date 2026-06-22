output "cluster_iam_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.arn
}

output "cluster_iam_role_name" {
  description = "Name of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.name
}

output "node_iam_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = aws_iam_role.eks_node.arn
}

output "node_iam_role_name" {
  description = "Name of the EKS node group IAM role"
  value       = aws_iam_role.eks_node.name
}

output "lambda_execution_role_arn" {
  description = "ARN of the Lambda FinOps execution role"
  value       = aws_iam_role.lambda_finops.arn
}

output "lambda_execution_role_name" {
  description = "Name of the Lambda FinOps execution role"
  value       = aws_iam_role.lambda_finops.name
}

output "github_oidc_role_arn" {
  description = "ARN of the GitHub Actions OIDC IAM role"
  value       = aws_iam_role.github_actions.arn
}

output "github_oidc_provider_arn" {
  description = "ARN of the GitHub Actions OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}
