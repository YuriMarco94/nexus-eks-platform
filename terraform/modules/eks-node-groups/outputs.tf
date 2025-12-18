output "node_group_id" {
  description = "ID do node group"
  value       = aws_eks_node_group.main.id
}

output "node_group_arn" {
  description = "ARN do node group"
  value       = aws_eks_node_group.main.arn
}

output "node_group_name" {
  description = "Nome do node group"
  value       = aws_eks_node_group.main.node_group_name
}

output "node_group_status" {
  description = "Status do node group"
  value       = aws_eks_node_group.main.status
}

output "node_group_labels" {
  description = "Labels configurados nos nodes"
  value       = aws_eks_node_group.main.labels
}
