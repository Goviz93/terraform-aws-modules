# ─────────────────────────────────────────────────────────────────────────────
# ECS IAM - inputs
# ─────────────────────────────────────────────────────────────────────────────

variable "name" {
  description = "Base name/prefix (e.g., myapp-prod)."
  type        = string
}

# Suma permisos SSM Messages al TASK ROLE para ECS Exec
variable "enable_ecs_exec" {
  description = "Add SSM messages actions to task role (ECS Exec)."
  type        = bool
  default     = true
}

# POLÍTICAS DEL TASK ROLE (app)
variable "task_managed_policy_arns" {
  description = "AWS managed/custom managed policies to attach to TASK role."
  type        = list(string)
  default     = []
}

variable "task_inline_policies" {
  description = "Map(name => JSON policy) inline for TASK role (e.g., Secrets/S3)."
  type        = map(string)
  default     = {}
}

# POLÍTICAS DEL EXECUTION ROLE (pull image, logs, etc.)
# Siempre se adjunta AmazonECSTaskExecutionRolePolicy; estas son extra
variable "execution_managed_policy_arns" {
  description = "Extra managed policies for EXECUTION role."
  type        = list(string)
  default     = []
}

variable "execution_inline_policies" {
  description = "Map(name => JSON policy) inline for EXECUTION role."
  type        = map(string)
  default     = {}
}

# TAGS corporativos
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
  description = "Optional extra tags."
  type        = map(string)
  default     = {}
}

