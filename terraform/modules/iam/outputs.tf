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

output "eks_oidc_provider_arn" {
  description = "ARN do OIDC Provider"
  value       = try(aws_iam_openid_connect_provider.eks[0].arn, "")
}

output "eks_oidc_provider_url" {
  description = "URL do OIDC Provider"
  value       = try(aws_iam_openid_connect_provider.eks[0].url, "")
}