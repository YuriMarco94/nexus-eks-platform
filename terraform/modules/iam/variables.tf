variable "project_name" {
  description = "Nome do projeto"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment deve ser: dev, staging ou prod."
  }
}

variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "github_repo" {
  description = "Repo GitHub org/repo (ex: minha-org/nexus-eks-platform)"
  type        = string
  default     = ""
}

variable "enable_github_actions_oidc" {
  description = "Cria OIDC + role para GitHub Actions"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags para os recursos IAM"
  type        = map(string)
  default     = {}
}
