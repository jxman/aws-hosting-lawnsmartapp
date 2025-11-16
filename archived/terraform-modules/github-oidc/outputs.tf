output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions"
  value       = aws_iam_role.github_actions_role.arn
}

output "github_actions_role_name" {
  description = "Name of the IAM role for GitHub Actions"
  value       = aws_iam_role.github_actions_role.name
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github_actions.arn
}