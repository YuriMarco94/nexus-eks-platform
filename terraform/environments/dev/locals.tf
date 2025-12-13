# Configurações locais e nomes padronizados
locals {
  # Nomes padronizados
  cluster_name   = "${var.project_name}-${var.environment}"
  vpc_name       = "${var.project_name}-${var.environment}-vpc"
  eks_role_name  = "${var.project_name}-${var.environment}-eks-role"
  node_role_name = "${var.project_name}-${var.environment}-node-role"

  # Availability Zones (2 zonas para alta disponibilidade)
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]

  # Tags comuns
  common_tags = merge(var.global_tags, {
    Environment = var.environment
    Terraform   = "true"
    LastUpdated = formatdate("YYYY-MM-DD hh:mm:ss", timestamp())
  })

  # Tags específicas por módulo
  networking_tags = merge(local.common_tags, {
    Component = "networking"
  })

  eks_tags = merge(local.common_tags, {
    Component                                     = "eks"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  })

  # Mapeamento de ambientes para configurações
  environment_config = {
    dev = {
      eks_endpoint_public_access       = true
      eks_endpoint_private_access      = false
      eks_endpoint_public_access_cidrs = ["0.0.0.0/0"]
      eks_managed_node_groups = {
        main = {
          instance_types = ["t3.medium"]
          capacity_type  = "ON_DEMAND" # ⬅️ ADICIONADO AQUI
          min_size       = 2
          desired_size   = 2
          max_size       = 3
          disk_size      = 20           # ⬅️ ADICIONADO AQUI
          ami_type       = "AL2_x86_64" # ⬅️ ADICIONADO AQUI
          update_config = {
            max_unavailable_percentage = 33
          }
          labels = {
            "node-type" = "main"
          }
        }
      }
    }
    staging = {
      eks_endpoint_public_access  = false
      eks_endpoint_private_access = true
      eks_managed_node_groups = {
        main = {
          instance_types = ["t3.large"]
          capacity_type  = "ON_DEMAND" # ⬅️ ADICIONADO AQUI
          min_size       = 2
          desired_size   = 3
          max_size       = 4
          disk_size      = 20           # ⬅️ ADICIONADO AQUI
          ami_type       = "AL2_x86_64" # ⬅️ ADICIONADO AQUI
        }
      }
    }
    prod = {
      eks_endpoint_public_access  = false
      eks_endpoint_private_access = true
      eks_managed_node_groups = {
        main = {
          instance_types = ["m5.large", "m5.xlarge"]
          capacity_type  = "ON_DEMAND" # ⬅️ ADICIONADO AQUI
          min_size       = 3
          desired_size   = 3
          max_size       = 6
          disk_size      = 50           # ⬅️ ADICIONADO AQUI
          ami_type       = "AL2_x86_64" # ⬅️ ADICIONADO AQUI
        }
      }
    }
  }

  # Configurações específicas do ambiente
  env_config = local.environment_config[var.environment]
}