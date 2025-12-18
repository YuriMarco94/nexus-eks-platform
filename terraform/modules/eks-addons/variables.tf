variable "cluster_name" {
  type = string
}

variable "enable_vpc_cni" {
  type    = bool
  default = true
}

variable "enable_kube_proxy" {
  type    = bool
  default = true
}

variable "enable_coredns" {
  type    = bool
  default = true
}

variable "enable_aws_ebs_csi_driver" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
