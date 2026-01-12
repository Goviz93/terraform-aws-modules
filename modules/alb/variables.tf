# ─────────────────────────────────────────────────────────────────────────────
# ALB module inputs
# ─────────────────────────────────────────────────────────────────────────────

variable "name" {
  description = "Base name/prefix for ALB and related resources (e.g., app-prod)."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB will be created."
  type        = string
}

variable "subnet_ids" {
  description = "List of PUBLIC subnet IDs (across 2+ AZs) for the ALB."
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Provide at least two subnets (multi-AZ)."
  }
}

variable "internal" {
  description = "If true, create an internal ALB; otherwise internet-facing."
  type        = bool
  default     = false
}

# Security group ingress
variable "allowed_ingress_cidrs" {
  description = "CIDR blocks allowed to reach the ALB on ports 80/443."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_ingress_sg_ids" {
  description = "Optional security group IDs allowed to reach the ALB."
  type        = list(string)
  default     = []
}

# Listeners
variable "enable_http_redirect_to_https" {
  description = "Create HTTP :80 listener that redirects to HTTPS :443."
  type        = bool
  default     = true
}

variable "enable_https_listener" {
  description = "Create HTTPS :443 listener."
  type        = bool
  default     = true
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener (required if enable_https_listener = true)."
  type        = string
  default     = ""
}

variable "additional_certificate_arns" {
  description = "Optional extra ACM certs for SNI."
  type        = list(string)
  default     = []
}

variable "ssl_policy" {
  description = "SSL policy for HTTPS listener."
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

# ALB settings
variable "deletion_protection" {
  description = "Enable deletion protection on the ALB."
  type        = bool
  default     = true
}

variable "idle_timeout" {
  description = "Idle timeout (seconds)."
  type        = number
  default     = 60
}

variable "drop_invalid_header_fields" {
  description = "Drop invalid HTTP header fields."
  type        = bool
  default     = true
}

variable "enable_http2" {
  description = "Enable HTTP/2 on the ALB."
  type        = bool
  default     = true
}

variable "ip_address_type" {
  description = "IP address type: ipv4 or dualstack."
  type        = string
  default     = "ipv4"
  validation {
    condition     = contains(["ipv4", "dualstack"], var.ip_address_type)
    error_message = "ip_address_type must be 'ipv4' or 'dualstack'."
  }
}

# Access logs
variable "access_logs_enabled" {
  description = "Enable ALB access logs to S3."
  type        = bool
  default     = false
}

variable "access_logs_bucket" {
  description = "S3 bucket name for ALB access logs (required if access_logs_enabled = true)."
  type        = string
  default     = ""
}

variable "access_logs_prefix" {
  description = "S3 prefix for ALB access logs."
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

# Extra/override tags
variable "tags" {
  description = "Optional extra tags to merge with standard tags."
  type        = map(string)
  default     = {}
}

