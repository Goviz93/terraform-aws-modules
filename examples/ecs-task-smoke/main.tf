# ─────────────────────────────────────────────────────────────────────────────
# examples/ecs-task-smoke/main.tf
# Smoke test: ECS Task Definition (Fargate) + IAM (del módulo ecs/iam)
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ── IAM mínimo para Task/Execution Role (reutiliza el módulo ecs/iam)
module "ecs_iam_smoke" {
  source = "../../modules/ecs/iam"

  name = "ecs-task-smoke"

  enable_ecs_exec = false

  standard_tags = {
    Project         = "platform"
    Owner           = "devops"
    ClickupID       = "CU-000"
    ClickupURL      = "https://app.clickup.com/t/CU-000"
    Environment     = "smoke"
    CostCenter      = "IT"
    Department      = "Engineering"
    Application     = "ecs-task-smoke"
    ManagedByTool   = "terraform"
    CreatedBy       = "iac"
    Backup          = "false"
    Confidentiality = "internal"
    ExpirationDate  = "2099-12-31"
  }

  tags = {
    Purpose = "ecs-task-smoke"
  }
}

# ── ECS Task Definition (módulo bajo prueba)
module "ecs_task_smoke" {
  source = "../../modules/ecs/task"

  family             = "ecs-task-smoke"
  cpu                = 256
  memory             = 512
  task_role_arn      = module.ecs_iam_smoke.task_role_arn
  execution_role_arn = module.ecs_iam_smoke.execution_role_arn

  container_name  = "nginx"
  container_image = "nginx:stable"

  container_port_mappings = [{
    container_port = 80
    protocol       = "tcp"
  }]

  container_environment = {
    APP_ENV = "smoke"
  }

  # Logs (el módulo puede crear el Log Group)
  logs_enabled          = true
  logs_create_log_group = true
  logs_group_name       = "" # usa fallback: /ecs/${family}/${container_name}
  logs_stream_prefix    = "app"
  logs_retention_days   = 7

  # Sin EFS para el smoke
  efs_volumes = []

  standard_tags = {
    Project         = "platform"
    Owner           = "devops"
    ClickupID       = "CU-000"
    ClickupURL      = "https://app.clickup.com/t/CU-000"
    Environment     = "smoke"
    CostCenter      = "IT"
    Department      = "Engineering"
    Application     = "ecs-task-smoke"
    ManagedByTool   = "terraform"
    CreatedBy       = "iac"
    Backup          = "false"
    Confidentiality = "internal"
    ExpirationDate  = "2099-12-31"
  }

  tags = {
    Purpose = "ecs-task-smoke"
  }
}

# ── Salidas útiles del smoke
output "task_definition_arn" {
  value = module.ecs_task_smoke.task_definition_arn
}

output "logs_group_name" {
  value = module.ecs_task_smoke.logs_group_name
}

# ── Variables del example
variable "region" {
  description = "AWS Region para el smoke test."
  type        = string
  default     = "us-east-1"
}

