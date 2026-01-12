# ─────────────────────────────────────────────────────────────────────────────
# modules/ecs/task/main.tf
# ─────────────────────────────────────────────────────────────────────────────

# (Opcional) Crear el Log Group si se habilitó y se solicitó su creación
resource "aws_cloudwatch_log_group" "this" {
  count             = var.logs_enabled && var.logs_create_log_group ? 1 : 0
  name              = length(var.logs_group_name) > 0 ? var.logs_group_name : local.effective_log_group_name
  retention_in_days = var.logs_retention_days
  tags              = local.default_tags
}

# Definición de la Task Definition (Fargate)
resource "aws_ecs_task_definition" "this" {
  family                   = var.family
  cpu                      = tostring(var.cpu)
  memory                   = tostring(var.memory)
  network_mode             = var.network_mode
  requires_compatibilities = var.requires_compatibilities
  task_role_arn            = var.task_role_arn
  execution_role_arn       = var.execution_role_arn

  runtime_platform {
    cpu_architecture        = var.runtime_cpu_architecture   # "X86_64" | "ARM64"
    operating_system_family = var.runtime_os_family          # "LINUX"
  }

  # Almacenamiento efímero ampliado (21–200 GiB)
  ephemeral_storage {
    size_in_gib = var.ephemeral_storage_gib
  }

  # Definición del contenedor principal (normalizada en locals)
  container_definitions = jsonencode([
    merge(
      {
        name       = var.container_name
        image      = var.container_image
        essential  = true
        environment = local.env_list
        secrets     = local.secrets_list
      },
      # Solo incluir logConfiguration si logs_enabled
      local.has_logs ? {
        logConfiguration = {
          logDriver = "awslogs"
          options   = local.awslogs_options
        }
      } : {},
      # Solo incluir si existen
      length(local.port_mappings) > 0 ? { portMappings = local.port_mappings } : {},
      length(local.mount_points)  > 0 ? { mountPoints  = local.mount_points }  : {},
      length(var.container_entrypoint) > 0 ? { entryPoint = var.container_entrypoint } : {},
      length(var.container_command)    > 0 ? { command    = var.container_command }    : {}
    )
  ])

  # Volúmenes (EFS) opcionales
  dynamic "volume" {
    for_each = local.efs_volumes_norm
    content {
      name = volume.value.name
      efs_volume_configuration {
        file_system_id     = volume.value.file_system_id
        root_directory     = volume.value.root_directory
        transit_encryption = "ENABLED"
        authorization_config {
          access_point_id = volume.value.access_point_id
          iam             = volume.value.use_authz ? "ENABLED" : "DISABLED"
        }
      }
    }
  }

  tags = local.default_tags
}

