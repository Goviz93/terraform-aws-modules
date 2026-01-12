# ─────────────────────────────────────────────────────────────────────────────
# modules/ecs/task/outputs.tf
# ─────────────────────────────────────────────────────────────────────────────

output "task_definition_arn" {
  description = "ARN de la Task Definition."
  value       = aws_ecs_task_definition.this.arn
}

output "task_family" {
  description = "Familia (nombre) de la Task Definition."
  value       = aws_ecs_task_definition.this.family
}

output "task_revision" {
  description = "Revisión publicada de la Task Definition."
  value       = aws_ecs_task_definition.this.revision
}

output "logs_group_name" {
  description = "Nombre efectivo del Log Group de CloudWatch (vacío si logs deshabilitados)."
  value       = var.logs_enabled ? local.effective_log_group_name : ""
}

