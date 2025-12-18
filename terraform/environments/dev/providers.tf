terraform {
  required_version = "~> 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.29.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13.0"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  default_tags {
    tags = local.common_tags
  }
}

# Token de auth pro cluster (usado nos providers kubernetes/helm)
#data "aws_eks_cluster_auth" "this" {
#  name = module.eks_cluster.cluster_name
#}

#provider "kubernetes" {
#  host                   = module.eks_cluster.cluster_endpoint
#  cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)
#  token                  = data.aws_eks_cluster_auth.this.token
#}

#provider "helm" {
#  kubernetes {
#    host                   = module.eks_cluster.cluster_endpoint
#    cluster_ca_certificate = base64decode(module.eks_cluster.cluster_certificate_authority_data)
#    token                  = data.aws_eks_cluster_auth.this.token
#  }
#}
