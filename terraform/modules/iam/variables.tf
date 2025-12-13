variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment deve ser: dev, staging ou prod."
  }
}

variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "oidc_provider_url" {
  description = "URL do OIDC provider do EKS"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags para os recursos IAM"
  type        = map(string)
  default     = {}
}