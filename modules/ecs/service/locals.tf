# ─────────────────────────────────────────────────────────────────────────────
# modules/ecs/service/locals.tf (versión corregida)
# ─────────────────────────────────────────────────────────────────────────────

locals {
  # Tags corporativos + extras + metadatos del módulo
  module_base_tags = { ManagedBy = "terraform", Module = "ecs-service" }
  default_tags     = merge(var.standard_tags, var.tags, local.module_base_tags)

  # Nombre efectivo del service
  service_name = var.name

  # ¿Se adjunta LB? (solo si se entregan TG y contenedor destino)
  use_lb = var.enable_load_balancer && length(var.target_group_arn) > 0 && length(var.lb_container_name) > 0

  # Métrica para autoscaling (target tracking)
  as_metric = lower(var.autoscaling_metric_type) == "memory"
    ? "ECSServiceAverageMemoryUtilization"
    : "ECSServiceAverageCPUUtilization"
}
# ─────────────────────────────────────────────────────────────────────────────
