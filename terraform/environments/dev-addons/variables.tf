variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_profile" {
  type    = string
  default = "eks-dev"
}

variable "infra_state_bucket" {
  type    = string
  default = "nexus-597088058179-terraform-state-dev"
}

variable "infra_state_key" {
  type    = string
  default = "eks-cluster/terraform.tfstate"
}

variable "enable_cloudwatch_observability_addon" {
  type    = bool
  default = true
}

variable "kubernetes_dashboard_chart_version" {
  type    = string
  default = "7.13.0"
}
