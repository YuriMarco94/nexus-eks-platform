variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment deve ser: dev, staging ou prod."
  }
}

variable "enable_cloudwatch_metrics" {
  description = "Habilitar métricas do CloudWatch"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_logs" {
  description = "Habilitar logs do CloudWatch"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Dias de retenção dos logs"
  type        = number
  default     = 30
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653], var.log_retention_days)
    error_message = "Valores válidos: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653."
  }
}

variable "tags" {
  description = "Tags para recursos"
  type        = map(string)
  default     = {}
}

variable "cluster_endpoint" {
  description = "Endpoint do cluster EKS"
  type        = string
  default     = ""
}

variable "cluster_ca_certificate" {
  description = "Certificate authority data do cluster"
  type        = string
  default     = ""
  sensitive   = true
}

variable "enable_prometheus" {
  description = "Habilitar Prometheus"
  type        = bool
  default     = false
}

variable "enable_grafana" {
  description = "Habilitar Grafana"
  type        = bool
  default     = false
}

variable "enable_alertmanager" {
  description = "Habilitar Alertmanager"
  type        = bool
  default     = false
}

variable "prometheus_retention" {
  description = "Período de retenção do Prometheus"
  type        = string
  default     = "7d"
}