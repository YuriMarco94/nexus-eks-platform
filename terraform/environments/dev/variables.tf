# =========================
# CORE
# =========================
variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment deve ser: dev, staging ou prod."
  }
}

variable "project_name" {
  description = "Nome do projeto (ex: Nexus, Phoenix, Atlas)"
  type        = string
  default     = "Nexus"

  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9-]{1,20}$", var.project_name))
    error_message = "project_name deve iniciar com letra maiúscula e ter 2-20 caracteres."
  }
}

variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  type        = string
  default     = null
  description = "AWS profile local (opcional). No CI, deixe null para usar OIDC."
}

# Repo no formato: org/repo (usado no OIDC do GitHub Actions)
variable "github_repo" {
  description = "Repo GitHub no formato https://github.com/YuriMarco94/nexus-eks-platform.git"
  type        = string
  default     = ""
}

variable "enable_github_actions_oidc" {
  description = "Cria OIDC + role para GitHub Actions assumir na AWS"
  type        = bool
  default     = true
}

# =========================
# NETWORK
# =========================
variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDRs para subnets privadas (recomendo mesma quantidade das públicas)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs para subnets públicas (recomendo mesma quantidade das privadas)"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

# =========================
# EKS
# =========================
variable "eks_cluster_version" {
  description = "Versão do Kubernetes"
  type        = string
  default     = "1.30"
}

variable "eks_endpoint_public_access" {
  description = "Habilitar acesso público ao endpoint do EKS"
  type        = bool
  default     = true
}

variable "eks_endpoint_private_access" {
  description = "Habilitar acesso privado ao endpoint do EKS"
  type        = bool
  default     = false
}

variable "eks_endpoint_public_access_cidrs" {
  description = "CIDRs permitidas para acesso público (se habilitado)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "eks_enabled_cluster_log_types" {
  description = "Tipos de log habilitados para o cluster"
  type        = list(string)
  default     = ["api", "audit"]
}

variable "enable_aws_ebs_csi_driver" {
  description = "Instala addon aws-ebs-csi-driver (sem IRSA por enquanto)"
  type        = bool
  default     = true
}

# =========================
# NODE GROUPS
# =========================
variable "eks_managed_node_groups" {
  description = "Configurações dos Managed Node Groups"
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = number
    ami_type       = string
    update_config = optional(object({
      max_unavailable_percentage = optional(number)
      max_unavailable            = optional(number)
    }))
    labels = optional(map(string))
    taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })))
  }))

  default = {
    main = {
      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"
      min_size       = 2
      max_size       = 4
      desired_size   = 2
      disk_size      = 20
      ami_type       = "AL2_x86_64"
      update_config = {
        max_unavailable_percentage = 33
      }
      labels = {
        "node-type" = "main"
      }
    }
  }
}

# =========================
# TAGS
# =========================
variable "global_tags" {
  description = "Tags globais"
  type        = map(string)
  default = {
    ManagedBy  = "Terraform"
    CostCenter = "EAGLE-01"
    Owner      = "DevOps-Eagles"
    Repository = "nexus-eks-platform"
  }
}
