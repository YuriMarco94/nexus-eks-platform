variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "node_group_name" {
  description = "Nome do node group"
  type        = string
}

variable "subnet_ids" {
  description = "IDs das subnets"
  type        = list(string)
}

variable "node_role_arn" {
  description = "ARN da role IAM dos nodes"
  type        = string
}

variable "instance_types" {
  description = "Tipos de instância"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "capacity_type" {
  description = "Tipo de capacidade"
  type        = string
  default     = "ON_DEMAND"
  validation {
    condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
    error_message = "Capacity type deve ser ON_DEMAND ou SPOT."
  }
}

variable "min_size" {
  description = "Número mínimo de nodes"
  type        = number
  default     = 1
  validation {
    condition     = var.min_size >= 0
    error_message = "min_size deve ser maior ou igual a 0."
  }
}

variable "max_size" {
  description = "Número máximo de nodes"
  type        = number
  default     = 10
  validation {
    condition     = var.max_size >= var.min_size
    error_message = "max_size deve ser maior ou igual a min_size."
  }
}

variable "desired_size" {
  description = "Número desejado de nodes"
  type        = number
  default     = 1
  validation {
    condition     = var.desired_size >= var.min_size && var.desired_size <= var.max_size
    error_message = "desired_size deve estar entre min_size e max_size."
  }
}

variable "disk_size" {
  description = "Tamanho do disco em GB"
  type        = number
  default     = 20
  validation {
    condition     = var.disk_size >= 20 && var.disk_size <= 100
    error_message = "disk_size deve estar entre 20 e 100 GB."
  }
}

variable "ami_type" {
  description = "Tipo de AMI"
  type        = string
  default     = "AL2_x86_64"
  validation {
    condition     = contains(["AL2_x86_64", "AL2_x86_64_GPU", "AL2_ARM_64", "CUSTOM"], var.ami_type)
    error_message = "AMI type inválido. Use: AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, CUSTOM."
  }
}

variable "update_config" {
  description = "Configuração de atualização"
  type = object({
    max_unavailable_percentage = optional(number)
    max_unavailable            = optional(number)
  })
  default = {}
}

variable "labels" {
  description = "Labels Kubernetes para os nodes"
  type        = map(string)
  default     = {}
}

variable "taints" {
  description = "Taints Kubernetes para os nodes"
  type = list(object({
    key    = string
    value  = string
    effect = string
  }))
  default = []
}

variable "tags" {
  description = "Tags para os recursos"
  type        = map(string)
  default     = {}
}