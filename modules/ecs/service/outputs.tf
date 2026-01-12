# ─────────────────────────────────────────────────────────────────────────────
# modules/ecs/service/outputs.tf
# ─────────────────────────────────────────────────────────────────────────────

output "service_name" {
  description = "Nombre del ECS Service."
  value       = aws_ecs_service.this.name
}

output "service_arn" {
  description = "ARN del ECS Service."
  value       = aws_ecs_service.this.id
}

output "cluster_arn" {
  description = "ARN del cluster donde corre el Service."
  value       = aws_ecs_service.this.cluster
}

output "task_definition" {
  description = "Task Definition en uso por el Service."
  value       = aws_ecs_service.this.task_definition
}

output "desired_count" {
  description = "Número deseado de tasks."
  value       = aws_ecs_service.this.desired_count
}

output "lb_attached" {
  description = "Indica si el Service está adjunto a un Target Group."
  value       = local.use_lb
}

output "lb_target_group_arn" {
  description = "ARN del Target Group (vacío si no aplica)."
  value       = local.use_lb ? var.target_group_arn : ""
}

output "execute_command_enabled" {
  description = "Si ECS Exec está habilitado."
  value       = var.enable_execute_command
}

# Auto Scaling (si está habilitado)
output "autoscaling_enabled" {
  description = "Si Application Auto Scaling está habilitado."
  value       = var.enable_autoscaling
}

output "autoscaling_resource_id" {
  description = "Resource ID usado por App Auto Scaling (vacío si no aplica)."
  value       = var.enable_autoscaling ? aws_appautoscaling_target.this[0].resource_id : ""
}

output "autoscaling_policy_name" {
  description = "Nombre de la política Target Tracking (vacío si no aplica)."
  value       = var.enable_autoscaling ? aws_appautoscaling_policy.target_tracking[0].name : ""
}

