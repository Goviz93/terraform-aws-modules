# ─────────────────────────────────────────────────────────────────────────────
# ECS Cluster - outputs
# ─────────────────────────────────────────────────────────────────────────────

output "cluster_id" {
  description = "ECS Cluster ID."
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ECS Cluster ARN."
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "ECS Cluster name."
  value       = aws_ecs_cluster.this.name
}

output "capacity_providers" {
  description = "Capacity providers enabled in the cluster."
  value       = local.cp_list
}

output "default_capacity_provider_strategy" {
  description = "Default capacity provider strategy applied to new services."
  value       = local.capacity_provider_strategy
}

output "cloud_map_namespace_id" {
  description = "Private DNS namespace ID (if created)."
  value       = length(aws_service_discovery_private_dns_namespace.this) > 0 ? aws_service_discovery_private_dns_namespace.this[0].id : null
}

output "cloud_map_namespace_arn" {
  description = "Private DNS namespace ARN (if created)."
  value       = length(aws_service_discovery_private_dns_namespace.this) > 0 ? aws_service_discovery_private_dns_namespace.this[0].arn : null
}

