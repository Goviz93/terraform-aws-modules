# ─────────────────────────────────────────────────────────────────────────────
# ALB module outputs
# ─────────────────────────────────────────────────────────────────────────────

output "security_group_id" {
  description = "Security Group ID attached to the ALB."
  value       = aws_security_group.alb.id
}

output "alb_arn" {
  description = "ARN of the ALB."
  value       = aws_lb.this.arn
}

output "alb_name" {
  description = "Name of the ALB."
  value       = aws_lb.this.name
}

output "alb_dns_name" {
  description = "Public DNS name of the ALB."
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Route53 hosted zone ID for the ALB DNS name."
  value       = aws_lb.this.zone_id
}

output "http_listener_arn" {
  description = "HTTP :80 listener ARN (null if not created)."
  value       = length(aws_lb_listener.http) > 0 ? aws_lb_listener.http[0].arn : null
}

output "https_listener_arn" {
  description = "HTTPS :443 listener ARN (null if not created)."
  value       = length(aws_lb_listener.https) > 0 ? aws_lb_listener.https[0].arn : null
}

