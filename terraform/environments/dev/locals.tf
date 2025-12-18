locals {
  cluster_name   = "${var.project_name}-${var.environment}"
  vpc_name       = "${var.project_name}-${var.environment}-vpc"
  eks_role_name  = "${var.project_name}-${var.environment}-eks-role"
  node_role_name = "${var.project_name}-${var.environment}-node-role"

  # usa data source, não “us-east-1a/b” hardcoded
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)

  common_tags = merge(var.global_tags, {
    Environment = var.environment
    Terraform   = "true"
  })

  networking_tags = merge(local.common_tags, { Component = "networking" })

  eks_tags = merge(local.common_tags, {
    Component                                     = "eks"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
  })

  env_config = local.environment_config[var.environment]

  environment_config = {
    dev = {
      eks_endpoint_public_access       = true
      eks_endpoint_private_access      = false
      eks_endpoint_public_access_cidrs = ["0.0.0.0/0"]
      eks_managed_node_groups = {
        main = {
          instance_types = ["t3.medium"]
          capacity_type  = "ON_DEMAND"
          min_size       = 2
          desired_size   = 2
          max_size       = 4
          disk_size      = 20
          ami_type       = "AL2_x86_64"
          update_config  = { max_unavailable_percentage = 33 }
          labels         = { "node-type" = "main" }
        }
      }
    }

    staging = {
      eks_endpoint_public_access  = false
      eks_endpoint_private_access = true
      eks_managed_node_groups = {
        main = {
          instance_types = ["t3.large"]
          capacity_type  = "ON_DEMAND"
          min_size       = 2
          desired_size   = 3
          max_size       = 4
          disk_size      = 20
          ami_type       = "AL2_x86_64"
        }
      }
    }

    prod = {
      eks_endpoint_public_access  = false
      eks_endpoint_private_access = true
      eks_managed_node_groups = {
        main = {
          instance_types = ["m5.large", "m5.xlarge"]
          capacity_type  = "ON_DEMAND"
          min_size       = 3
          desired_size   = 3
          max_size       = 6
          disk_size      = 50
          ami_type       = "AL2_x86_64"
        }
      }
    }
  }
}
