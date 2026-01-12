# ─────────────────────────────────────────────────────────────────────────────
# VPC module inputs
# ─────────────────────────────────────────────────────────────────────────────

variable "name" {
  description = "Name/prefix used for naming and tagging (e.g., myapp-prod)."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g., 10.10.0.0/16)."
  type        = string
}

variable "azs" {
  description = "Availability Zones to use (e.g., [\"us-east-1a\", \"us-east-1b\"])."
  type        = list(string)
  validation {
    condition     = length(var.azs) >= 2
    error_message = "Provide at least two AZs."
  }
}

variable "public_cidrs" {
  description = "CIDRs for public subnets (must match azs length)."
  type        = list(string)
  validation {
    condition     = length(var.public_cidrs) == length(var.azs)
    error_message = "public_cidrs length must match azs length."
  }
}

variable "app_cidrs" {
  description = "CIDRs for application subnets (must match azs length)."
  type        = list(string)
  validation {
    condition     = length(var.app_cidrs) == length(var.azs)
    error_message = "app_cidrs length must match azs length."
  }
}

variable "db_cidrs" {
  description = "CIDRs for database subnets (must match azs length)."
  type        = list(string)
  validation {
    condition     = length(var.db_cidrs) == length(var.azs)
    error_message = "db_cidrs length must match azs length."
  }
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

# Additional/override tags
variable "tags" {
  description = "Optional extra tags to merge with standard tags."
  type        = map(string)
  default     = {}
}

# Internet & NAT
variable "enable_nat" {
  description = "Create NAT Gateway(s) for private subnets egress."
  type        = bool
  default     = true
}

variable "enable_nat_per_az" {
  description = "If true, one NAT per AZ; otherwise a single shared NAT."
  type        = bool
  default     = false
}

# VPC Endpoints
variable "enable_s3_gateway" {
  description = "Create S3 Gateway VPC Endpoint."
  type        = bool
  default     = true
}

variable "enable_interface_endpoints" {
  description = "Create Interface Endpoints (SSM, SSMMessages, EC2Messages, Secrets Manager, Logs, ECR API/DKR)."
  type        = bool
  default     = true
}

# Flow Logs
variable "enable_flow_logs" {
  description = "Enable VPC Flow Logs to CloudWatch Logs."
  type        = bool
  default     = true
}

variable "flow_logs_retention_days" {
  description = "Retention (days) for CloudWatch Logs group used by VPC Flow Logs."
  type        = number
  default     = 30
}

