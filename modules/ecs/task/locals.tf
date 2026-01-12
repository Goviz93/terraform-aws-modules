# ─────────────────────────────────────────────────────────────────────────────
# Locals: tags, naming, logs, normalización de inputs
# ─────────────────────────────────────────────────────────────────────────────

data "aws_region" "current" {}

locals {
  # Tags
  module_base_tags = { ManagedBy = "terraform", Module = "ecs-task" }
  default_tags     = merge(var.standard_tags, var.tags, local.module_base_tags)

  name_prefix = var.family

  # Región de logs: var.awslogs_region (si viene) ó región actual
# Después
  logs_region = length(var.awslogs_region) > 0 ? var.awslogs_region : data.aws_region.current.id

  # Nombre por defecto del Log Group si logs_enabled y no se pasó uno
  effective_log_group_name = var.logs_enabled ? (length(var.logs_group_name) > 0 ? var.logs_group_name : "/ecs/${var.family}/${var.container_name}") : ""

  # Opciones awslogs (solo si logs_enabled)
  awslogs_options = var.logs_enabled ? {
    "awslogs-group"         = local.effective_log_group_name
    "awslogs-region"        = local.logs_region
    "awslogs-stream-prefix" = var.logs_stream_prefix
  } : {}

  # Env vars: map -> lista
  env_list = [
    for k, v in var.container_environment : {
      name  = k
      value = v
    }
  ]

  # Secrets: preferimos map(name => arn); si viene vacío, aceptamos la lista legacy
  secrets_list = length(var.container_secrets_map) > 0 ? [
    for k, v in var.container_secrets_map : {
      name      = k
      valueFrom = v
    }
  ] : [
    for s in var.container_secrets : {
      name      = s.name
      valueFrom = s.value_from
    }
  ]

  # Port mappings: omitimos hostPort (awsvpc lo iguala automáticamente)
  port_mappings = [
    for p in var.container_port_mappings : {
      containerPort = p.container_port
      protocol      = lower(p.protocol)  # "tcp" | "udp"
    }
  ]

  # Mount points (para EFS)
  mount_points = [
    for m in var.container_mount_points : {
      sourceVolume  = m.source_volume
      containerPath = m.container_path
      readOnly      = m.read_only
    }
  ]

  # EFS volumes: normalizados para usar dynamic blocks en main.tf
  efs_volumes_norm = [
    for v in var.efs_volumes : {
      name            = v.name
      file_system_id  = v.file_system_id
      root_directory  = v.root_directory
      access_point_id = v.access_point_id
      use_authz       = length(v.access_point_id) > 0  # habilita iam sólo si hay AP
    }
  ]

  has_logs       = var.logs_enabled
  has_efs_volume = length(var.efs_volumes) > 0
}

