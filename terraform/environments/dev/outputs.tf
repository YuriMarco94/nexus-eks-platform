output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = module.eks_cluster.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  value       = module.eks_cluster.cluster_endpoint
  sensitive   = true
}

output "cluster_certificate_authority_data" {
  description = "Dados do CA do cluster (base64)"
  value       = module.eks_cluster.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "URL do OIDC Issuer do cluster (IRSA)"
  value       = module.eks_cluster.cluster_oidc_issuer_url
}

output "eks_oidc_provider_arn" {
  description = "ARN do OIDC Provider criado na AWS para o EKS"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "vpc_id" {
  description = "ID da VPC"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas"
  value       = module.networking.public_subnet_ids
}

output "configure_kubectl" {
  description = "Comando para configurar kubectl"
  value       = "aws eks update-kubeconfig --name ${module.eks_cluster.cluster_name} --region ${var.aws_region} --profile ${var.aws_profile}"
}

output "deployment_summary" {
  description = "Resumo da implantação"
  value       = <<-EOT
  =================================================
  NEXUS EKS CLUSTER - DEPLOYMENT SUMMARY
  =================================================

  Cluster: ${module.eks_cluster.cluster_name}
  Region:  ${var.aws_region}
  Profile: ${var.aws_profile}
  Environment: ${var.environment}

  Configure kubectl:
  aws eks update-kubeconfig --name ${module.eks_cluster.cluster_name} --region ${var.aws_region} --profile ${var.aws_profile}

  Validate:
  kubectl cluster-info
  kubectl get nodes
  EOT
}
