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
    error_message = "capacity_type deve ser ON_DEMAND ou SPOT."
  }
}

variable "min_size" {
  description = "Número mínimo de nodes"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Número máximo de nodes"
  type        = number
  default     = 10
}

variable "desired_size" {
  description = "Número desejado de nodes"
  type        = number
  default     = 1
}

variable "disk_size" {
  description = "Tamanho do disco em GB"
  type        = number
  default     = 20
}

variable "ami_type" {
  description = "Tipo de AMI"
  type        = string
  default     = "AL2_x86_64"
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
