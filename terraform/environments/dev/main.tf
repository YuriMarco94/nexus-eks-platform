# terraform/environments/dev/main.tf

# =========================
# DATA
# =========================
data "aws_availability_zones" "available" {
  state = "available"
}

# Thumbprint OIDC do EKS (só funciona após cluster existir)
data "tls_certificate" "eks_oidc" {
  url = module.eks_cluster.cluster_oidc_issuer_url
}

# Validações práticas (evita mismatch NAT/subnets)
resource "null_resource" "validate_subnets" {
  triggers = {
    public_len  = tostring(length(var.public_subnet_cidrs))
    private_len = tostring(length(var.private_subnet_cidrs))
  }

  lifecycle {
    precondition {
      condition     = length(var.public_subnet_cidrs) == length(var.private_subnet_cidrs)
      error_message = "public_subnet_cidrs e private_subnet_cidrs devem ter o MESMO tamanho."
    }

    precondition {
      condition     = length(var.public_subnet_cidrs) >= 2
      error_message = "Use pelo menos 2 subnets públicas/privadas (>=2 AZs) para EKS ficar saudável."
    }
  }
}

# =========================
# NETWORKING
# =========================
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

# =========================
# IAM (cluster + nodes + GitHub OIDC)
# =========================
module "iam" {
  source = "../../modules/iam"

  project_name               = var.project_name
  environment                = var.environment
  cluster_name               = local.cluster_name
  github_repo                = var.github_repo
  enable_github_actions_oidc = var.enable_github_actions_oidc

  tags = merge(local.common_tags, { Component = "iam" })
}

# =========================
# EKS CLUSTER
# =========================
module "eks_cluster" {
  source = "../../modules/eks-cluster"

  cluster_name    = local.cluster_name
  cluster_version = var.eks_cluster_version

  cluster_endpoint_public_access       = var.eks_endpoint_public_access
  cluster_endpoint_private_access      = var.eks_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.eks_endpoint_public_access_cidrs

  vpc_id         = module.networking.vpc_id
  subnet_ids     = module.networking.private_subnet_ids
  cluster_sg_ids = [module.networking.eks_cluster_security_group_id]

  cluster_role_arn = module.iam.eks_cluster_role_arn
  node_role_arn    = module.iam.eks_node_role_arn

  enabled_cluster_log_types = var.eks_enabled_cluster_log_types

  tags = local.eks_tags

  depends_on = [module.networking, module.iam]
}

# =========================
# OIDC PROVIDER DO EKS (IRSA base)
# =========================
resource "aws_iam_openid_connect_provider" "eks" {
  url             = module.eks_cluster.cluster_oidc_issuer_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_oidc.certificates[0].sha1_fingerprint]
  tags            = local.common_tags
}

# =========================
# EKS ADDONS - PRE NODES (CNI + kube-proxy)
# - Esses precisam existir ANTES do nodegroup, senão os nodes tendem a ficar NotReady
# =========================
module "eks_addons_pre" {
  source = "../../modules/eks-addons"

  cluster_name = module.eks_cluster.cluster_name
  tags         = local.eks_tags

  # requer adicionar essas variáveis no módulo eks-addons (enable_vpc_cni/enable_kube_proxy/enable_coredns)
  enable_vpc_cni    = true
  enable_kube_proxy = true
  enable_coredns    = false

  # EBS CSI não deve rodar antes de ter node (vai ficar DEGRADED / Pending)
  enable_aws_ebs_csi_driver = false

  depends_on = [module.eks_cluster]
}

# =========================
# MANAGED NODE GROUPS
# =========================
module "eks_managed_node_groups" {
  source = "../../modules/eks-node-groups"

  for_each = var.eks_managed_node_groups

  cluster_name    = module.eks_cluster.cluster_name
  node_group_name = "${local.cluster_name}-${each.key}"
  subnet_ids      = module.networking.private_subnet_ids

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

  node_role_arn = module.iam.eks_node_role_arn

  tags = merge(local.eks_tags, { NodeGroup = each.key })

  # GARANTE ordem correta: primeiro CNI/kube-proxy, depois nodes
  depends_on = [module.eks_addons_pre]
}

# =========================
# EKS ADDONS - POST NODES (CoreDNS + EBS CSI)
# - Esses precisam de node pronto para agendar pods
# =========================
module "eks_addons_post" {
  source = "../../modules/eks-addons"

  cluster_name = module.eks_cluster.cluster_name
  tags         = local.eks_tags

  enable_vpc_cni    = false
  enable_kube_proxy = false
  enable_coredns    = true

  enable_aws_ebs_csi_driver = var.enable_aws_ebs_csi_driver

  depends_on = [module.eks_managed_node_groups]
}
