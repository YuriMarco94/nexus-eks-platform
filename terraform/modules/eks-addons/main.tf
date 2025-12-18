resource "aws_eks_addon" "vpc_cni" {
  count        = var.enable_vpc_cni ? 1 : 0
  cluster_name = var.cluster_name
  addon_name   = "vpc-cni"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  timeouts {
    create = "40m"
    update = "40m"
    delete = "40m"
  }
}

resource "aws_eks_addon" "kube_proxy" {
  count        = var.enable_kube_proxy ? 1 : 0
  cluster_name = var.cluster_name
  addon_name   = "kube-proxy"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  timeouts {
    create = "40m"
    update = "40m"
    delete = "40m"
  }
}

resource "aws_eks_addon" "coredns" {
  count        = var.enable_coredns ? 1 : 0
  cluster_name = var.cluster_name
  addon_name   = "coredns"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  timeouts {
    create = "40m"
    update = "40m"
    delete = "40m"
  }
}

resource "aws_eks_addon" "ebs_csi" {
  count        = var.enable_aws_ebs_csi_driver ? 1 : 0
  cluster_name = var.cluster_name
  addon_name   = "aws-ebs-csi-driver"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags

  timeouts {
    create = "40m"
    update = "40m"
    delete = "40m"
  }
}
