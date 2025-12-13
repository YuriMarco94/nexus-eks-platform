# Variáveis principais
variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment deve ser: dev, staging ou prod."
  }
}

variable "project_name" {
  description = "Nome do projeto (ex: Nexus, Phoenix, Atlas)"
  type        = string
  default     = "Nexus"

  validation {
    condition     = can(regex("^[A-Z][a-zA-Z0-9-]{1,20}$", var.project_name))
    error_message = "Nome do projeto deve iniciar com letra maiúscula e ter 2-20 caracteres."
  }
}

variable "aws_region" {
  description = "Região AWS"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Perfil AWS CLI para autenticação"
  type        = string
  default     = "nexus-alpha"
}

# Configurações de rede
variable "vpc_cidr" {
  description = "CIDR da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDRs para subnets privadas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDRs para subnets públicas"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

# Configurações EKS
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

# Configurações de Node Groups
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

# Tags
variable "global_tags" {
  description = "Tags globais para todos os recursos"
  type        = map(string)
  default = {
    Project     = "Nexus"
    ManagedBy   = "Terraform"
    Repository  = "github.com/org/aws-eks-nexus"
    CostCenter  = "EAGLE-01"
    Owner       = "DevOps-Eagles"
    Environment = "dev"
  }
}

# Configuração específica para node groups - sincronizada com locals.tf
variable "eks_node_group_config" {
  description = "Configuração simplificada para node groups"
  type = object({
    instance_types = list(string)
    capacity_type  = string
    min_size       = number
    max_size       = number
    desired_size   = number
    disk_size      = number
    ami_type       = string
  })
  default = {
    instance_types = ["t3.medium"]
    capacity_type  = "ON_DEMAND"
    min_size       = 2
    max_size       = 4
    desired_size   = 2
    disk_size      = 20
    ami_type       = "AL2_x86_64"
  }
}