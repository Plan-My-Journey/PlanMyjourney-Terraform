output "github_connection_arn" {
  description = "CodeConnections ARN for GitHub GitOps repo"
  value       = aws_codestarconnections_connection.github.arn
}

output "flux_source_role_arn" {
  description = "IRSA role ARN for Flux source-controller"
  value       = aws_iam_role.flux_source.arn
}

output "gitops_repo_url" {
  description = "GitOps repository URL for Flux GitRepository"
  value       = "https://github.com/${var.github_org}/${var.gitops_repo}"
}

output "gitops_path" {
  description = "Kustomize overlay path reconciled by Flux"
  value       = var.gitops_path
}
