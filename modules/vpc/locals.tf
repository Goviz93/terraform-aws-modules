# ─────────────────────────────────────────────────────────────────────────────
# Locals: naming, tags, derived lists, endpoints, flags
# ─────────────────────────────────────────────────────────────────────────────

locals {
  # Base tags auto-added by module
  module_base_tags = {
    ManagedBy = "terraform"
    Module    = "vpc"
  }

  # Final tags used across resources
  default_tags = merge(
    var.standard_tags,
    var.tags,
    local.module_base_tags
  )

  # Naming
  name_prefix = var.name

  # NAT flags
  use_nat    = var.enable_nat
  nat_per_az = var.enable_nat && var.enable_nat_per_az && length(var.azs) > 1

  # VPC Interface Endpoints to create (regional service short names)
  interface_endpoint_services = var.enable_interface_endpoints ? [
    "ssm",
    "ssmmessages",
    "ec2messages",
    "secretsmanager",
    "logs",
    "ecr.api",
    "ecr.dkr"
  ] : []

  # VPC Gateway Endpoints to create
  gateway_endpoint_services = var.enable_s3_gateway ? ["s3"] : []

  # Normalized subnet definitions (used with for_each in main.tf)
  public_subnets = [
    for i, cidr in var.public_cidrs : {
      name = "${local.name_prefix}-pub-${i}"
      cidr = cidr
      az   = var.azs[i]
      tags = merge(local.default_tags, {
        Name       = "${local.name_prefix}-pub-${i}"
        SubnetType = "public"
      })
    }
  ]

  app_subnets = [
    for i, cidr in var.app_cidrs : {
      name = "${local.name_prefix}-app-${i}"
      cidr = cidr
      az   = var.azs[i]
      tags = merge(local.default_tags, {
        Name       = "${local.name_prefix}-app-${i}"
        SubnetType = "app"
      })
    }
  ]

  db_subnets = [
    for i, cidr in var.db_cidrs : {
      name = "${local.name_prefix}-db-${i}"
      cidr = cidr
      az   = var.azs[i]
      tags = merge(local.default_tags, {
        Name       = "${local.name_prefix}-db-${i}"
        SubnetType = "db"
      })
    }
  ]

  # CloudWatch Logs group for VPC Flow Logs
  flow_logs_group_name = "/vpc/${local.name_prefix}/flow-logs"
}

