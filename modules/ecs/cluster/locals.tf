# ─────────────────────────────────────────────────────────────────────────────
# Locals: tags, naming, capacity helpers
# ─────────────────────────────────────────────────────────────────────────────
locals {
  module_base_tags = {
    ManagedBy = "terraform"
    Module    = "ecs-cluster"
  }

  default_tags = merge(
    var.standard_tags,
    var.tags,
    local.module_base_tags
  )

  name_prefix = var.name

  # Normaliza capacity providers (FARGATE / FARGATE_SPOT)
  cp_list = distinct(var.capacity_providers)

  # Estrategia por defecto (solo incluye providers activos y con weight > 0)
  # Nota: 'base' se aplica al provider FARGATE (garantiza N tareas on-demand).
  capacity_provider_strategy = [
    for s in [
      { cp = "FARGATE",       base = var.capacity_strategy.base, weight = var.capacity_strategy.fargate_weight },
      { cp = "FARGATE_SPOT",  base = 0,                           weight = var.capacity_strategy.fargate_spot_weight }
    ] : {
      capacity_provider = s.cp
      base              = s.base
      weight            = s.weight
    }
    if contains(local.cp_list, s.cp) && s.weight > 0
  ]
}

