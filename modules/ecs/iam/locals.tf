# ─────────────────────────────────────────────────────────────────────────────
# Locals: tags, naming
# ─────────────────────────────────────────────────────────────────────────────
locals {
  module_base_tags = {
    ManagedBy = "terraform"
    Module    = "ecs-iam"
  }

  default_tags = merge(
    var.standard_tags,
    var.tags,
    local.module_base_tags
  )

  name_prefix = var.name
}

