# ─────────────────────────────────────────────────────────────────────────────
# ECS Cluster - inputs
# ─────────────────────────────────────────────────────────────────────────────

variable "name" {
  description = "Cluster name/prefix (e.g., myenv-prod)."
  type        = string
}

variable "enable_container_insights" {
  description = "Enable CloudWatch Container Insights."
  type        = bool
  default     = true
}

# Capacity providers to attach to the cluster.
# Valid values: FARGATE, FARGATE_SPOT
variable "capacity_providers" {
  description = "List of capacity providers to enable."
  type        = list(string)
  default     = ["FARGATE", "FARGATE_SPOT"]
}

# Default strategy for new services in this cluster.
# 'base' usually on FARGATE to guarantee at least N on-demand tasks.
variable "capacity_strategy" {
  description = "Default capacity provider strategy (weights & base)."
  type = object({
    fargate_weight       = number
    fargate_spot_weight  = number
    base                 = number
  })
  default = {
    fargate_weight      = 1
    fargate_spot_weight = 0
    base                = 1
  }
}

# Optional: Private DNS namespace (AWS Cloud Map) for service discovery.
variable "enable_cloud_map" {
  description = "Create a private DNS namespace (Cloud Map) in this VPC."
  type        = bool
  default     = false
}

variable "cloud_map_namespace_name" {
  description = "Private DNS namespace name (e.g., svc.local). Required if enable_cloud_map=true."
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID for the private DNS namespace. Required if enable_cloud_map=true."
  type        = string
  default     = ""
}

# Corporate standard tags (typed map)
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

