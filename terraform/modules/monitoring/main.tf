# ============================================
# CLOUDWATCH LOG GROUPS
# ============================================

resource "aws_cloudwatch_log_group" "eks_cluster" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name      = "${var.cluster_name}-cluster-logs"
    Component = "cloudwatch-logs"
  })
}

resource "aws_cloudwatch_log_group" "eks_containers" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name              = "/aws/eks/${var.cluster_name}/containers"
  retention_in_days = var.log_retention_days

  tags = merge(var.tags, {
    Name      = "${var.cluster_name}-container-logs"
    Component = "cloudwatch-logs"
  })
}

# ============================================
# CLOUDWATCH METRIC ALARMS
# ============================================

resource "aws_cloudwatch_metric_alarm" "node_cpu_high" {
  count = var.enable_cloudwatch_metrics ? 1 : 0

  alarm_name          = "${var.cluster_name}-node-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "CPU utilização alta nos nós EKS"
  alarm_actions       = [] # Adicione SNS topics aqui se necessário
  
  dimensions = {
    AutoScalingGroupName = var.cluster_name
  }

  tags = merge(var.tags, {
    Component = "cloudwatch-alarm"
  })
}

resource "aws_cloudwatch_metric_alarm" "node_memory_high" {
  count = var.enable_cloudwatch_metrics ? 1 : 0

  alarm_name          = "${var.cluster_name}-node-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/EC2"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "Memória utilização alta nos nós EKS"
  alarm_actions       = [] # Adicione SNS topics aqui se necessário
  
  dimensions = {
    AutoScalingGroupName = var.cluster_name
  }

  tags = merge(var.tags, {
    Component = "cloudwatch-alarm"
  })
}

# ============================================
# CLOUDWATCH DASHBOARD
# ============================================
resource "aws_cloudwatch_dashboard" "eks_dashboard" {
  count = var.enable_cloudwatch_metrics ? 1 : 0
  
  dashboard_name = "${var.cluster_name}-dashboard"
  
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "AutoScalingGroupName", var.cluster_name, { stat = "Average", label = "CPU" }],
            ["System/Linux", "MemoryUtilization", "AutoScalingGroupName", var.cluster_name, { stat = "Average", label = "Memory" }]
          ]
          view   = "timeSeries"
          stacked = false
          region = data.aws_region.current.name
          title  = "EKS Node Resources"
          period = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EKS", "ClusterFailedNodeCount", "ClusterName", var.cluster_name, { stat = "Average", label = "Failed Nodes" }],
            ["AWS/EKS", "ClusterNodeCount", "ClusterName", var.cluster_name, { stat = "Average", label = "Total Nodes" }]
          ]
          view   = "timeSeries"
          stacked = false
          region = data.aws_region.current.name
          title  = "EKS Cluster Health"
          period = 300
        }
      }
    ]
  })
}  # ⬅️ ESTE É O } QUE ESTÁ FALTANDO!

# Data source para região
data "aws_region" "current" {}