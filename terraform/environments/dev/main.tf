# ============================================

# Módulo de Networking
module "networking" {
  source = "../../modules/networking"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = local.availability_zones
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs

  tags = local.networking_tags
}

# Módulo de IAM
module "iam" {
  source = "../../modules/iam"

  project_name      = var.project_name
  environment       = var.environment
  cluster_name      = local.cluster_name
  oidc_provider_url = "" # ⬅️ INICIALMENTE VAZIO - será preenchido depois

  # IMPORTANTE: Adicionar dependência explícita
  depends_on = [module.networking]

  tags = local.common_tags
}

# Módulo EKS Cluster
module "eks_cluster" {
  source = "../../modules/eks-cluster"

  # Configurações básicas
  cluster_name                         = local.cluster_name
  cluster_version                      = var.eks_cluster_version
  cluster_endpoint_public_access       = local.env_config.eks_endpoint_public_access
  cluster_endpoint_private_access      = local.env_config.eks_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.eks_endpoint_public_access_cidrs

  # VPC e Subnets
  vpc_id         = module.networking.vpc_id
  subnet_ids     = module.networking.private_subnet_ids
  cluster_sg_ids = [module.networking.eks_cluster_security_group_id]

  # IAM Roles
  cluster_role_arn = module.iam.eks_cluster_role_arn
  node_role_arn    = module.iam.eks_node_role_arn

  # Configurações avançadas
  enabled_cluster_log_types = var.eks_enabled_cluster_log_types

  # Add-ons
  enable_aws_ebs_csi_driver = true

  tags = local.eks_tags

  depends_on = [
    module.networking,
    module.iam
  ]
}

# Módulo de Managed Node Groups
module "eks_managed_node_groups" {
  source = "../../modules/eks-node-groups"

  for_each = local.env_config.eks_managed_node_groups

  cluster_name    = module.eks_cluster.cluster_name
  node_group_name = "${local.cluster_name}-${each.key}"
  subnet_ids      = module.networking.private_subnet_ids

  # Configurações do Node Group - AGORA COM TODOS OS CAMPOS NECESSÁRIOS
  instance_types = each.value.instance_types
  capacity_type  = each.value.capacity_type
  min_size       = each.value.min_size
  max_size       = each.value.max_size
  desired_size   = each.value.desired_size
  disk_size      = each.value.disk_size
  ami_type       = each.value.ami_type
  update_config  = try(each.value.update_config, {})
  labels         = try(each.value.labels, {})
  taints         = try(each.value.taints, [])

  # IAM
  node_role_arn = module.iam.eks_node_role_arn

  # Tags
  tags = merge(local.eks_tags, {
    NodeGroup = each.key
  })

  depends_on = [
    module.eks_cluster,
    module.iam
  ]
}

# ============================================
# OUTPUTS
# ============================================

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
  description = "URL do OIDC Issuer para IAM Roles for Service Accounts"
  value       = module.eks_cluster.cluster_oidc_issuer_url
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
  
  Para configurar kubectl:
  aws eks update-kubeconfig --name ${module.eks_cluster.cluster_name} --region ${var.aws_region} --profile ${var.aws_profile}
  
  Para verificar o cluster:
  kubectl cluster-info
  kubectl get nodes
  
  EOT
}
