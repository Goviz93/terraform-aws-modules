
# ─────────────────────────────────────────────────────────────────────────────
# ECS Task Definition (Fargate) - variables
# ─────────────────────────────────────────────────────────────────────────────

# Nombre/familia de la task definition (se versiona por revisiones)
variable "family" {
  description = "Task family/name (e.g., myapp-prod)."
  type        = string
  validation {
    condition     = length(trimspace(var.family)) > 0
    error_message = "family no puede estar vacío."
  }
}

# Recursos a nivel de TAREA (no por contenedor)
# Fargate CPU válidos: 256, 512, 1024, 2048, 4096 (vCPU * 1024)
variable "cpu" {
  description = "Task CPU units for Fargate (256, 512, 1024, 2048, 4096)."
  type        = number
  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.cpu)
    error_message = "cpu must be one of: 256, 512, 1024, 2048, 4096."
  }
}

# Fargate Memory en MiB (debe ser compatible con el CPU elegido).
variable "memory" {
  description = "Task memory (MiB) compatible with selected CPU (see AWS Fargate limits)."
  type        = number
  validation {
    condition = contains(
      lookup({
        256  = [512, 1024, 2048]
        512  = [1024, 2048, 3072, 4096]
        1024 = [2048, 3072, 4096, 5120, 6144, 7168, 8192]
        2048 = [4096, 5120, 6144, 7168, 8192, 9216, 10240, 11264, 12288, 13312, 14336, 15360, 16384]
        4096 = [8192, 9216, 10240, 11264, 12288, 13312, 14336, 15360, 16384, 17408, 18432, 19456, 20480, 21504, 22528, 23552, 24576, 25600, 26624, 27648, 28672, 29696, 30720]
      }, var.cpu, []),
      var.memory
    )
    error_message = "memory no es compatible con el cpu elegido (valores permitidos por Fargate)."
  }
}

# Roles
variable "task_role_arn" {
  description = "IAM Task Role ARN (app permissions)."
  type        = string
}

variable "execution_role_arn" {
  description = "IAM Execution Role ARN (ECR pull, logs, etc.)."
  type        = string
}

# Plataforma/Compatibilidad
variable "runtime_cpu_architecture" {
  description = "CPU architecture: X86_64 or ARM64."
  type        = string
  default     = "X86_64"
  validation {
    condition     = contains(["X86_64", "ARM64"], var.runtime_cpu_architecture)
    error_message = "runtime_cpu_architecture must be X86_64 or ARM64."
  }
}

variable "runtime_os_family" {
  description = "OS family: LINUX (Fargate)."
  type        = string
  default     = "LINUX"
  validation {
    condition     = var.runtime_os_family == "LINUX"
    error_message = "Only LINUX is supported for Fargate."
  }
}

variable "network_mode" {
  description = "Must be awsvpc for Fargate."
  type        = string
  default     = "awsvpc"
  validation {
    condition     = var.network_mode == "awsvpc"
    error_message = "network_mode must be awsvpc for Fargate."
  }
}

variable "requires_compatibilities" {
  description = "ECS compatibilities. Use [\"FARGATE\"]."
  type        = list(string)
  default     = ["FARGATE"]
  validation {
    condition     = contains(var.requires_compatibilities, "FARGATE")
    error_message = "requires_compatibilities debe incluir \"FARGATE\"."
  }
}

# Región opcional para awslogs (si no, se usa la región actual)
variable "awslogs_region" {
  description = "Override for CloudWatch Logs region (defaults to current region)."
  type        = string
  default     = ""
}

# Secretos como map(name => arn). Mantiene compat con container_secrets (lista).
variable "container_secrets_map" {
  description = "Secrets as a map of name => valueFrom (ARN[:jsonKey[:version]])."
  type        = map(string)
  default     = {}
}

# Almacenamiento efímero ampliado (21–200 GiB)
variable "ephemeral_storage_gib" {
  description = "Ephemeral storage size in GiB (21-200)."
  type        = number
  default     = 21
  validation {
    condition     = var.ephemeral_storage_gib >= 21 && var.ephemeral_storage_gib <= 200
    error_message = "ephemeral_storage_gib must be between 21 and 200."
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Contenedor principal
# ─────────────────────────────────────────────────────────────────────────────

variable "container_name" {
  description = "Main container name."
  type        = string
  validation {
    condition     = length(trimspace(var.container_name)) > 0
    error_message = "container_name no puede estar vacío."
  }
}

variable "container_image" {
  description = "Main container image (e.g., <account>.dkr.ecr.<region>.amazonaws.com/repo:tag)."
  type        = string
  validation {
    condition     = length(trimspace(var.container_image)) > 0
    error_message = "container_image no puede estar vacío."
  }
}

variable "container_port_mappings" {
  description = "List of port mappings for the main container."
  type = list(object({
    container_port = number
    protocol       = string # "tcp" | "udp"
  }))
  default = []
  validation {
    condition     = alltrue([for p in var.container_port_mappings : contains(["tcp", "udp"], lower(p.protocol))])
    error_message = "container_port_mappings.protocol debe ser tcp o udp."
  }
}

variable "container_command" {
  description = "Optional command override (ENTRYPOINT/CMD) for the main container."
  type        = list(string)
  default     = []
}

variable "container_entrypoint" {
  description = "Optional entrypoint override."
  type        = list(string)
  default     = []
}

variable "container_environment" {
  description = "Environment variables for the main container."
  type        = map(string)
  default     = {}
}

variable "container_secrets" {
  description = "Secrets for the main container (legacy list). value_from = ARN[:jsonKey[:versionStage|versionId]]."
  type = list(object({
    name       = string
    value_from = string
  }))
  default = []
}

# Montajes (si usas EFS volumes)
variable "container_mount_points" {
  description = "Mount points for the main container (use with efs_volumes)."
  type = list(object({
    source_volume  = string
    container_path = string
    read_only      = bool
  }))
  default = []
}

# ─────────────────────────────────────────────────────────────────────────────
# Logs a CloudWatch (awslogs)
# ─────────────────────────────────────────────────────────────────────────────

variable "logs_enabled" {
  description = "Enable awslogs log driver for the main container."
  type        = bool
  default     = true
}

variable "logs_create_log_group" {
  description = "Create the CloudWatch Logs group (if true)."
  type        = bool
  default     = true
}

variable "logs_group_name" {
  description = "CloudWatch Logs group name (required if logs_enabled=true)."
  type        = string
  default     = ""
  validation {
    condition     = var.logs_enabled == false || var.logs_create_log_group == true || length(var.logs_group_name) > 0
    error_message = "Si logs_enabled=true y no se crea el log group, debes proveer logs_group_name."
  }
}

variable "logs_stream_prefix" {
  description = "CloudWatch Logs stream prefix."
  type        = string
  default     = "app"
}

variable "logs_retention_days" {
  description = "Retention in days for the log group (only used if create_log_group=true)."
  type        = number
  default     = 30
}

# ─────────────────────────────────────────────────────────────────────────────
# Volúmenes (opcional EFS en Fargate)
# ─────────────────────────────────────────────────────────────────────────────

variable "efs_volumes" {
  description = "EFS volumes to expose to the task (optional)."
  type = list(object({
    name            = string
    file_system_id  = string
    access_point_id = string
    root_directory  = string # e.g., "/"
  }))
  default = []
}

# ─────────────────────────────────────────────────────────────────────────────
# Tags corporativos
# ─────────────────────────────────────────────────────────────────────────────

variable "standard_tags" {
  description = "Corporate mandatory tags (case-sensitive)."
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
  description = "Optional extra tags to merge with standard tags."
  type        = map(string)
  default     = {}
}

