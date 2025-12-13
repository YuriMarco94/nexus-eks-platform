resource "aws_eks_node_group" "main" {
  cluster_name    = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  
  instance_types = var.instance_types
  capacity_type  = var.capacity_type
  disk_size      = var.disk_size
  ami_type       = var.ami_type
  
  scaling_config {
    desired_size = var.desired_size
    min_size     = var.min_size
    max_size     = var.max_size
  }
  
  dynamic "update_config" {
    for_each = length(keys(var.update_config)) > 0 ? [1] : []
    
    content {
      max_unavailable_percentage = try(var.update_config.max_unavailable_percentage, null)
      max_unavailable            = try(var.update_config.max_unavailable, null)
    }
  }
  
  labels = var.labels
  
  # CORREÇÃO: Use dynamic block para taints
  dynamic "taint" {
    for_each = var.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }
  
  tags = merge(var.tags, {
    Name        = var.node_group_name
    Component   = "eks-node-group"
    NodeGroup   = var.node_group_name
    CapacityType = var.capacity_type
  })
}

resource "aws_iam_role_policy_attachment" "nodes" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  ])
  
  role       = var.node_role_arn
  policy_arn = each.value
}