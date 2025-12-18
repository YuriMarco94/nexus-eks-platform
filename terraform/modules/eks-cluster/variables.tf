variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

variable "cluster_version" {
  description = "Versão do Kubernetes"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "subnet_ids" {
  description = "IDs das subnets"
  type        = list(string)
}

variable "cluster_sg_ids" {
  description = "IDs dos security groups do cluster"
  type        = list(string)
}

variable "cluster_role_arn" {
  description = "ARN da role IAM do cluster"
  type        = string
}

variable "node_role_arn" {
  description = "ARN da role IAM dos nodes"
  type        = string
  default     = null
}

variable "cluster_endpoint_public_access" {
  description = "Habilitar acesso público"
  type        = bool
  default     = false
}

variable "cluster_endpoint_private_access" {
  description = "Habilitar acesso privado"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs para acesso público"
  type        = list(string)
  default     = []
}

variable "enabled_cluster_log_types" {
  description = "Tipos de log habilitados"
  type        = list(string)
  default     = []
}

variable "enable_aws_ebs_csi_driver" {
  description = "Habilitar AWS EBS CSI Driver"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags para recursos"
  type        = map(string)
  default     = {}
}
