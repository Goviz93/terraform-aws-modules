# ALB Module

Crea un **Application Load Balancer** (interno o internet-facing) multi-AZ con:
- **Security Group** (HTTP/HTTPS), reglas opcionales por **CIDR** y/o **SG**.
- **ALB** con **2+ subnets** (requisito AWS), HTTP/2, idle timeout, drop invalid headers.
- **Listeners**:  
  - `:80` (opcional) → **redirect** a `:443`.  
  - `:443` con **SSL policy** y **ACM cert** (+ SNI extra opcional).
- **Access Logs** (opcional) a S3.

> **Nota:** Aunque sea “compartido” entre apps, el ALB **debe** asociarse a **subnets en ≥2 AZ**.  
> `internal=false` ⇒ usar **subnets públicas**. `internal=true` ⇒ usar **subnets privadas**.

---

## Requisitos
- Terraform `>= 1.6.0`
- Provider AWS `>= 5.0`
- Subnets en **≥2 AZ** (públicas o privadas según `internal`).

---

## Inputs (resumen)
- `name` *(string, requerido)*: prefijo (`myenv-prod`).
- `vpc_id` *(string, req.)*
- `subnet_ids` *(list(string), req.)*: **≥2** subnets en distintas AZ.
- `internal` *(bool, default `false`)*: interno vs internet-facing.
- **Ingress**:
  - `allowed_ingress_cidrs` *(list(string), default `["0.0.0.0/0"]`)*  
  - `allowed_ingress_sg_ids` *(list(string), default `[]`)*
- **Listeners**:
  - `enable_http_redirect_to_https` *(bool, default `true`)*
  - `enable_https_listener` *(bool, default `true`)*
  - `certificate_arn` *(string, req. si HTTPS=true)*
  - `additional_certificate_arns` *(list(string), default `[]`)*
  - `ssl_policy` *(string, default `ELBSecurityPolicy-TLS13-1-2-2021-06`)*
- **ALB settings**:
  - `deletion_protection` *(bool, default `true`)*
  - `idle_timeout` *(number, default `60`)*
  - `drop_invalid_header_fields` *(bool, default `true`)*
  - `enable_http2` *(bool, default `true`)*
  - `ip_address_type` *(string: `ipv4|dualstack`, default `ipv4`)*
- **Access logs**:
  - `access_logs_enabled` *(bool, default `false`)*
  - `access_logs_bucket` *(string, req. si enabled)*
  - `access_logs_prefix` *(string, default `""`)*
- **Tags**:
  - `standard_tags` *(object tipado corporativo, req.)*
  - `tags` *(map(string), default `{}`)*

---

## Outputs
- `security_group_id`
- `alb_arn`, `alb_name`, `alb_dns_name`, `alb_zone_id`
- `http_listener_arn` (o `null`)
- `https_listener_arn` (o `null`)

---

## Uso básico (internet-facing, subnets públicas)
```hcl
module "alb" {
  source     = "git::ssh://gitlab.com/yourorg/platform-modules-aws.git//modules/alb?ref=v0.1.0"
  name       = "shared-prod"
  vpc_id     = data.terraform_remote_state.vpc.outputs.vpc_id
  subnet_ids = data.terraform_remote_state.vpc.outputs.public_subnet_ids
  internal   = false

  certificate_arn = aws_acm_certificate.shared.arn

  standard_tags = var.standard_tags
}

