# ─────────────────────────────────────────────────────────────────────────────
# ECS Service (Fargate) - variables
# ─────────────────────────────────────────────────────────────────────────────

variable "name" {
  description = "Nombre del ECS Service."
  type        = string
}

variable "cluster_arn" {
  description = "ARN del ECS Cluster donde se creará el Service."
  type        = string
}

variable "task_definition_arn" {
  description = "ARN de la Task Definition a ejecutar."
  type        = string
}

variable "desired_count" {
  description = "Número deseado de tareas."
  type        = number
  default     = 1
  validation {
    condition     = var.desired_count >= 0
    error_message = "desired_count debe ser >= 0."
  }
}

variable "platform_version" {
  description = "Fargate platform version (e.g., 1.4.0, LATEST)."
  type        = string
  default     = "LATEST"
}

variable "assign_public_ip" {
  description = "Asignar IP pública (solo si subnets públicas)."
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "Subnets donde correrán las tasks (awsvpc)."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security Groups para las ENI de las tasks."
  type        = list(string)
  default     = []
}

# ── Load Balancer (ALB/NLB) opcional
variable "enable_load_balancer" {
  description = "Adjuntar el Service a un Target Group."
  type        = bool
  default     = true
}

variable "target_group_arn" {
  description = "ARN del Target Group."
  type        = string
  default     = ""
}

variable "lb_container_name" {
  description = "Nombre del contenedor a enrutar."
  type        = string
  default     = ""
}

variable "lb_container_port" {
  description = "Puerto del contenedor a enrutar."
  type        = number
  default     = 80
}

variable "health_check_grace_period_seconds" {
  description = "Tiempo de gracia para health checks del LB."
  type        = number
  default     = 60
}

# ── Deploy & control
variable "enable_deployment_circuit_breaker" {
  description = "Habilita circuit breaker (auto-rollback)."
  type        = bool
  default     = true
}

variable "deployment_minimum_healthy_percent" {
  description = "Mínimo % healthy durante despliegue."
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "Máximo % permitido durante despliegue."
  type        = number
  default     = 200
}

variable "enable_execute_command" {
  description = "Habilita ECS Exec (ssmmessages en Task Role)."
  type        = bool
  default     = false
}

variable "propagate_tags" {
  description = "Propagar tags (SERVICE|TASK_DEFINITION|NONE)."
  type        = string
  default     = "SERVICE"
  validation {
    condition     = contains(["SERVICE", "TASK_DEFINITION", "NONE"], var.propagate_tags)
    error_message = "propagate_tags debe ser SERVICE, TASK_DEFINITION o NONE."
  }
}

variable "enable_ecs_managed_tags" {
  description = "Habilita managed tags de ECS."
  type        = bool
  default     = true
}

# ── Capacity Provider (opcional)
variable "capacity_provider_strategy" {
  description = "Estrategia de capacity providers (FARGATE/FARGATE_SPOT)."
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = optional(number)
  }))
  default = []
}

# ── Service discovery (Cloud Map) opcional
variable "service_discovery_registries" {
  description = "Service registries (Cloud Map)."
  type = list(object({
    registry_arn   = string
    container_name = optional(string)
    container_port = optional(number)
    port           = optional(number)
  }))
  default = []
}

# ── Auto Scaling opcional (Target Tracking)
variable "enable_autoscaling" {
  description = "Habilitar Application Auto Scaling para el Service."
  type        = bool
  default     = false
}

variable "autoscaling_min_capacity" {
  description = "Mínimo tasks."
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Máximo tasks."
  type        = number
  default     = 3
}

variable "autoscaling_metric_type" {
  description = "cpu|memory (target tracking)."
  type        = string
  default     = "cpu"
  validation {
    condition     = contains(["cpu", "memory"], lower(var.autoscaling_metric_type))
    error_message = "autoscaling_metric_type debe ser cpu o memory."
  }
}

variable "autoscaling_target_value" {
  description = "Porcentaje objetivo (ej. 50)."
  type        = number
  default     = 50
}

# ── Tags corporativos
variable "standard_tags" {
  description = "Tags corporativos obligatorios."
  type = object({
    Project         = string
    Owner           = string
    ClickupID       = string
    ClickupURL      = string
    Environment     = string
    CostCenter      = string
    Department      = string
    Application     = string
    ManagedByTool   = string
    CreatedBy       = string
    Backup          = string
    Confidentiality = string
    ExpirationDate  = string
  })
}

variable "tags" {
  description = "Tags extra opcionales."
  type        = map(string)
  default     = {}
}

