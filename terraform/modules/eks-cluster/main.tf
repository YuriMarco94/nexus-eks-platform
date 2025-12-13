# Módulo: EKS Cluster
# Descrição: Cluster EKS com add-ons essenciais

# ============================================
# EKS CLUSTER
# ============================================
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.cluster_version
  
  enabled_cluster_log_types = var.enabled_cluster_log_types
  
  vpc_config {
    subnet_ids              = var.subnet_ids
    security_group_ids      = var.cluster_sg_ids
    endpoint_public_access  = var.cluster_endpoint_public_access
    endpoint_private_access = var.cluster_endpoint_private_access
    
    public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  }
  
  kubernetes_network_config {
    ip_family = "ipv4"
  }
  
  tags = var.tags
  
  depends_on = [
    aws_cloudwatch_log_group.eks
  ]
}

# ============================================
# CLOUDWATCH LOG GROUP
# ============================================
resource "aws_cloudwatch_log_group" "eks" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = 30
  
  tags = var.tags
}