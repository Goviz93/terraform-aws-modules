#############################################
# ECS Cluster (+ optional Cloud Map)
#############################################

resource "aws_ecs_cluster" "this" {
  name = local.name_prefix
  tags = merge(local.default_tags, { Name = local.name_prefix })

  # Container Insights (optional)
  dynamic "setting" {
    for_each = var.enable_container_insights ? [1] : []
    content {
      name  = "containerInsights"
      value = "enabled"
    }
  }
}

# Attach capacity providers and default strategy
resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = local.cp_list

  dynamic "default_capacity_provider_strategy" {
    for_each = local.capacity_provider_strategy
    content {
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
      base              = default_capacity_provider_strategy.value.base
      weight            = default_capacity_provider_strategy.value.weight
    }
  }

  lifecycle {
    precondition {
      condition     = length(local.cp_list) > 0
      error_message = "At least one capacity provider must be specified."
    }
  }
}

# Optional: Private DNS namespace (Cloud Map) for service discovery
resource "aws_service_discovery_private_dns_namespace" "this" {
  count = var.enable_cloud_map ? 1 : 0

  name = var.cloud_map_namespace_name
  vpc  = var.vpc_id
  tags = merge(local.default_tags, { Name = var.cloud_map_namespace_name })

  lifecycle {
    precondition {
      condition     = var.enable_cloud_map == false || (length(var.cloud_map_namespace_name) > 0 && length(var.vpc_id) > 0)
      error_message = "cloud_map_namespace_name and vpc_id are required when enable_cloud_map = true."
    }
  }
}

