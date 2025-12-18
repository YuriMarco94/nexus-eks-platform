# FinOps Terraform Module
module "finops" {
  source = "./modules/finops"

  environment    = var.environment
  cluster_name   = local.cluster_name
  monthly_budget = var.monthly_budget
  cost_center    = var.cost_center
  business_unit  = var.business_unit

  # Cost optimization features
  enable_spot_instances    = var.environment != "prod"
  enable_auto_scaling      = true
  enable_rightsizing       = true
  enable_shutdown_schedule = var.environment == "dev"

  # Tags for cost allocation
  cost_allocation_tags = merge(var.global_tags, {
    CostCenter         = var.cost_center
    BusinessUnit       = var.business_unit
    EnvironmentType    = var.environment
    WorkloadType       = "container-platform"
    DataClassification = "internal"
    Compliance         = "SOX,GDPR"
  })
}

# Spot Instance configuration with fallback
resource "aws_eks_node_group" "spot" {
  count = var.enable_spot_instances ? 1 : 0

  cluster_name    = module.eks_cluster.cluster_name
  node_group_name = "${local.cluster_name}-spot"
  node_role_arn   = module.iam.eks_node_role_arn
  subnet_ids      = module.networking.private_subnet_ids

  # Spot configuration with multiple instance types
  instance_types = [
    "t3.medium", "t3a.medium",
    "t3.large", "t3a.large",
    "m5.large", "m5a.large"
  ]

  capacity_type = "SPOT"
  disk_size     = 20
  ami_type      = "AL2_x86_64"

  scaling_config {
    desired_size = var.environment == "prod" ? 0 : 2
    min_size     = 0 # Scale to zero during off-hours
    max_size     = 10
  }

  # Spot allocation strategy for maximum savings
  launch_template {
    version = "$Latest"

    override {
      instance_type = "t3.medium"
    }

    override {
      instance_type = "t3a.medium"
    }

    market_options {
      market_type = "spot"
      spot_options {
        max_price                      = "0.05" # Maximum bid price
        instance_interruption_behavior = "TERMINATE"
      }
    }
  }

  tags = merge(local.eks_tags, {
    CostOptimization   = "spot-instances"
    Lifecycle          = "ephemeral"
    InterruptionNotice = "5m"
  })
}

# Auto-scaling based on cost metrics
resource "aws_autoscaling_policy" "cost_optimized_scaling" {
  name                   = "${local.cluster_name}-cost-optimized"
  autoscaling_group_name = module.eks_managed_node_groups["main"].node_group_arn

  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 65.0 # Optimize for 65% utilization
  }

  estimated_instance_warmup = 300 # 5 minutes
}

# Cost anomaly detection
resource "aws_ce_anomaly_monitor" "cost_anomaly" {
  name              = "${local.cluster_name}-cost-anomaly"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_ce_anomaly_subscription" "cost_anomaly_alerts" {
  name      = "${local.cluster_name}-anomaly-alerts"
  threshold = 50.0 # Alert when cost increases by 50%
  frequency = "DAILY"

  monitor_arn_list = [
    aws_ce_anomaly_monitor.cost_anomaly.arn
  ]

  subscriber {
    type    = "EMAIL"
    address = "finops-alerts@company.com"
  }

  tags = {
    Environment = var.environment
  }
}