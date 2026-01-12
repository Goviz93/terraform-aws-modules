# ─────────────────────────────────────────────────────────────────────────────
# VPC module outputs
# ─────────────────────────────────────────────────────────────────────────────

# Core
output "vpc_id" {
  description = "VPC ID."
  value       = aws_vpc.this.id
}

output "vpc_arn" {
  description = "VPC ARN."
  value       = aws_vpc.this.arn
}

output "vpc_cidr" {
  description = "VPC CIDR block."
  value       = var.vpc_cidr
}

output "azs" {
  description = "Availability Zones used by this VPC."
  value       = var.azs
}

output "internet_gateway_id" {
  description = "Internet Gateway ID."
  value       = aws_internet_gateway.this.id
}

# Subnets
output "public_subnet_ids" {
  description = "Public subnet IDs (ordered as provided)."
  value       = [for s in aws_subnet.public : s.id]
}

output "app_subnet_ids" {
  description = "Application (private) subnet IDs (ordered as provided)."
  value       = [for s in aws_subnet.app : s.id]
}

output "db_subnet_ids" {
  description = "Database (private) subnet IDs (ordered as provided)."
  value       = [for s in aws_subnet.db : s.id]
}

# Route tables
output "public_route_table_id" {
  description = "Public route table ID."
  value       = aws_route_table.public.id
}

output "app_route_table_ids" {
  description = "Map of app route table IDs keyed by subnet key."
  value       = { for k, rt in aws_route_table.app : k => rt.id }
}

output "db_route_table_ids" {
  description = "Map of DB route table IDs keyed by subnet key."
  value       = { for k, rt in aws_route_table.db : k => rt.id }
}

# NAT
output "nat_mode" {
  description = "NAT mode: per_az | shared | disabled."
  value       = local.nat_per_az ? "per_az" : (var.enable_nat ? "shared" : "disabled")
}

output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs (empty if NAT disabled)."
  value       = var.enable_nat ? [for _, nat in aws_nat_gateway.this : nat.id] : []
}

# VPC Endpoints
output "vpce_security_group_id" {
  description = "Security group ID used by Interface Endpoints."
  value       = aws_security_group.endpoints.id
}

output "interface_vpce_ids" {
  description = "Map of Interface Endpoint IDs keyed by service short name."
  value       = { for svc, ep in aws_vpc_endpoint.interface : svc => ep.id }
}

output "s3_gateway_vpce_id" {
  description = "S3 Gateway Endpoint ID (null if not created)."
  value       = length(aws_vpc_endpoint.s3) > 0 ? aws_vpc_endpoint.s3[0].id : null
}

# Flow logs
output "flow_logs_log_group_name" {
  description = "CloudWatch Logs group name for VPC Flow Logs (null if disabled)."
  value       = var.enable_flow_logs ? aws_cloudwatch_log_group.flow[0].name : null
}

