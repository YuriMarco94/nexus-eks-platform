output "cloudwatch_log_group_arns" {
  description = "ARNs dos CloudWatch Log Groups"
  value = concat(
    aws_cloudwatch_log_group.eks_cluster[*].arn,
    aws_cloudwatch_log_group.eks_containers[*].arn
  )
}

output "cloudwatch_alarm_names" {
  description = "Nomes dos CloudWatch Alarms"
  value = concat(
    aws_cloudwatch_metric_alarm.node_cpu_high[*].alarm_name,
    aws_cloudwatch_metric_alarm.node_memory_high[*].alarm_name
  )
}

output "cloudwatch_dashboard_name" {
  description = "Nome do CloudWatch Dashboard"
  value       = try(aws_cloudwatch_dashboard.eks_dashboard[0].dashboard_name, "")
}

output "log_retention_days" {
  description = "Dias de retenção configurados"
  value       = var.log_retention_days
}