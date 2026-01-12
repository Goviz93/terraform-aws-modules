# VPC Module

Módulo Terraform para crear la base de red: **VPC**, subnets (public/app/db), **IGW**, **NAT** (opcional, 1 o por AZ), **Route Tables**, **VPC Endpoints** (S3 Gateway + Interface: SSM/Secrets/Logs/ECR) y **VPC Flow Logs** (opcional).


## Requisitos
- Terraform **>= 1.6**
- Provider AWS **>= 5.0**
- Al menos **2 AZs** y listas de CIDRs con la **misma longitud** que `azs`.

## Qué crea
- VPC con DNS habilitado.
- Subnets: **public**, **app (privadas)**, **db (privadas, sin ruta 0.0.0.0/0)**.
- IGW y Route Tables (1 pública compartida; 1 por subnet app/db).
- NAT: **compartido** (default) o **uno por AZ** (`enable_nat_per_az`).
- VPC Endpoints:
  - **Gateway**: S3 (attach a RT de app/db).
  - **Interface**: `ssm`, `ssmmessages`, `ec2messages`, `secretsmanager`, `logs`, `ecr.api`, `ecr.dkr`.
- VPC Flow Logs → CloudWatch Logs (retención configurable).

## Inputs (resumen)
- `name` (string): prefijo (ej. `myapp-prod`).
- `vpc_cidr` (string): CIDR de la VPC (ej. `10.10.0.0/16`).
- `azs` (list(string)): AZs (ej. `["us-east-1a","us-east-1b"]`).
- `public_cidrs` / `app_cidrs` / `db_cidrs` (list(string)): deben **igualar** la longitud de `azs`.
- `standard_tags` (object): **tags corporativos obligatorios** (Project, Owner, ClickupID, …, ExpirationDate).
- `tags` (map(string), opcional): tags extra.
- Flags:
  - `enable_nat` (bool, default `true`)
  - `enable_nat_per_az` (bool, default `false`)
  - `enable_s3_gateway` (bool, default `true`)
  - `enable_interface_endpoints` (bool, default `true`)
  - `enable_flow_logs` (bool, default `true`)
  - `flow_logs_retention_days` (number, default `30`)

## Outputs (resumen)
- `vpc_id`, `vpc_arn`, `vpc_cidr`, `azs`
- `public_subnet_ids`, `app_subnet_ids`, `db_subnet_ids`
- `public_route_table_id`, `app_route_table_ids`, `db_route_table_ids`
- `nat_mode` (`per_az` | `shared` | `disabled`), `nat_gateway_ids`
- `vpce_security_group_id`, `interface_vpce_ids`, `s3_gateway_vpce_id`
- `flow_logs_log_group_name` (o `null`)

## Ejemplo de uso
```hcl
module "vpc" {
  source = "git::ssh://gitlab.com/yourorg/platform-modules.git//modules/vpc?ref=v0.1.0"

  name      = "myapp-prod"
  vpc_cidr  = "10.10.0.0/16"
  azs       = ["us-east-1a", "us-east-1b"]

  public_cidrs = ["10.10.0.0/20", "10.10.16.0/20"]
  app_cidrs    = ["10.10.32.0/20", "10.10.48.0/20"]
  db_cidrs     = ["10.10.64.0/24", "10.10.65.0/24"]

  standard_tags = {
    Project         = "cdn-cd-pipeline-efirma"
    Owner           = "miguel.rosas/gonzalo.viz"
    ClickupID       = "86aaqr398"
    ClickupURL      = "https://app.clickup.com/t/86ab27p4q"
    Environment     = "prod"
    CostCenter      = "development"
    Department      = "development"
    Application     = "gitlab-cd-s3"
    ManagedByTool   = "manual"
    CreatedBy       = "devops-gonzalo.vizcaino"
    Backup          = "none"
    Confidentiality = "public"
    ExpirationDate  = "2026-01-10"
  }

  tags = { CostOwner = "platform" }

  enable_nat                 = true
  enable_nat_per_az          = false
  enable_s3_gateway          = true
  enable_interface_endpoints = true
  enable_flow_logs           = true
  flow_logs_retention_days   = 30
}

