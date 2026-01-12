# ─────────────────────────────────────────────────────────────────────────────
# Locals: naming, tags, helpers
# ─────────────────────────────────────────────────────────────────────────────

locals {
  # Base tags auto
  module_base_tags = {
    ManagedBy = "terraform"
    Module    = "alb"
  }

  # Tags finales
  default_tags = merge(
    var.standard_tags,
    var.tags,
    local.module_base_tags
  )

  # Nombre base
  name_prefix = var.name

  # Ingress sources (normalizados)
  ingress_cidrs = distinct(var.allowed_ingress_cidrs)
  ingress_sgs   = distinct(var.allowed_ingress_sg_ids)

  # Access logs habilitados solo si hay bucket
  logs_enabled = var.access_logs_enabled && var.access_logs_bucket != ""

  # Descripción para SG
  sg_desc = var.internal ? "ALB internal ingress" : "ALB internet-facing ingress"
}

