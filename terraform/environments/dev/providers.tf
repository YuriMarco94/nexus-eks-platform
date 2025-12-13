terraform {
  required_version = "~> 1.9.0"
  required_providers {
    aws        = { source = "hashicorp/aws", version = "~> 5.0" }
    kubernetes = { source = "hashicorp/kubernetes", version = "~> 2.29.0" }
    helm       = { source = "hashicorp/helm", version = "~> 2.13.0" }
  }
}

provider "aws" {
  region  = "us-east-1"
  profile = "eks-dev"
  default_tags { tags = local.common_tags }
}

# Data source para auth token
data "aws_eks_cluster_auth" "this" {
  name = module.eks_cluster.cluster_name
}