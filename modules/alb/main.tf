#############################################
# Security Group
#############################################
resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = local.sg_desc
  vpc_id      = var.vpc_id

  # Ingress desde CIDRs (HTTP/HTTPS)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = local.ingress_cidrs
    description = "HTTP from allowed CIDRs"
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = local.ingress_cidrs
    description = "HTTPS from allowed CIDRs"
  }

  # Egress total
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All egress"
  }

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-alb-sg" })
}

# Ingress desde SGs (HTTP/HTTPS)
resource "aws_security_group_rule" "ingress_http_sg" {
  for_each                 = toset(local.ingress_sgs)
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.alb.id
  description              = "HTTP from allowed SG"
}

resource "aws_security_group_rule" "ingress_https_sg" {
  for_each                 = toset(local.ingress_sgs)
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = each.value
  security_group_id        = aws_security_group.alb.id
  description              = "HTTPS from allowed SG"
}

#############################################
# ALB
#############################################
resource "aws_lb" "this" {
  name                       = "${local.name_prefix}-alb"
  internal                   = var.internal
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = var.subnet_ids
  enable_deletion_protection = var.deletion_protection
  idle_timeout               = var.idle_timeout
  drop_invalid_header_fields = var.drop_invalid_header_fields
  enable_http2               = var.enable_http2
  ip_address_type            = var.ip_address_type

  dynamic "access_logs" {
    for_each = local.logs_enabled ? [1] : []
    content {
      bucket  = var.access_logs_bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-alb" })
}

#############################################
# Listeners
#############################################

# HTTP :80 → redirect a HTTPS (opcional)
resource "aws_lb_listener" "http" {
  count             = var.enable_http_redirect_to_https ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = local.default_tags
}

# HTTPS :443 con default 404 (reglas de apps se agregan aparte)
resource "aws_lb_listener" "https" {
  count             = var.enable_https_listener ? 1 : 0
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No matching rule"
      status_code  = "404"
    }
  }

  lifecycle {
    precondition {
      condition     = var.enable_https_listener == false || length(var.certificate_arn) > 0
      error_message = "certificate_arn is required when enable_https_listener = true."
    }
  }

  tags = local.default_tags
}

# Certificados adicionales (SNI)
resource "aws_lb_listener_certificate" "extra" {
  for_each        = var.enable_https_listener ? toset(var.additional_certificate_arns) : toset([])
  listener_arn    = aws_lb_listener.https[0].arn
  certificate_arn = each.value
}

