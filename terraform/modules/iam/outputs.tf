output "eks_cluster_role_arn" {
  description = "ARN da role IAM do cluster"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_cluster_role_name" {
  description = "Nome da role IAM do cluster"
  value       = aws_iam_role.eks_cluster.name
}

output "eks_node_role_arn" {
  description = "ARN da role IAM dos nodes"
  value       = aws_iam_role.eks_nodes.arn
}

output "eks_node_role_name" {
  description = "Nome da role IAM dos nodes"
  value       = aws_iam_role.eks_nodes.name
}

output "github_actions_role_arn" {
  value       = try(aws_iam_role.github_actions[0].arn, null)
  description = "ARN da role assumida pelo GitHub Actions via OIDC"
}
