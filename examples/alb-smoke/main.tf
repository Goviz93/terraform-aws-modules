terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

provider "aws" {
  region = var.aws_region
}

# Tomar 2 AZ válidas
data "aws_availability_zones" "available" {
  state = "available"
}
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

# 1) VPC mínima para el ALB
module "vpc" {
  source = "../../modules/vpc"

  name     = "alb-smoke-prod"
  vpc_cidr = "10.20.0.0/16"
  azs      = local.azs

  public_cidrs = ["10.20.0.0/20", "10.20.16.0/20"]
  app_cidrs    = ["10.20.32.0/20", "10.20.48.0/20"]
  db_cidrs     = ["10.20.64.0/24", "10.20.65.0/24"]

  # para hacer el plan más liviano (opcional)
  enable_flow_logs           = false
  enable_interface_endpoints = false
  enable_s3_gateway          = false
  enable_nat                 = false

  standard_tags = {
    Project         = "example"
    Owner           = "devops@example"
    ClickupID       = "N/A"
    ClickupURL      = "https://clickup.example/t/xxx"
    Environment     = "prod"
    CostCenter      = "platform"
    Department      = "platform"
    Application     = "alb-module-test"
    ManagedByTool   = "terraform"
    CreatedBy       = "devops"
    Backup          = "none"
    Confidentiality = "public"
    ExpirationDate  = "2030-01-01"
  }
}

# 2) ALB Internet-facing (sólo HTTP para evitar cert)
module "alb" {
  source = "../../modules/alb"

  name       = "shared-prod"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnet_ids
  internal   = false

  enable_http_redirect_to_https = false # no redirect
  enable_https_listener         = false # sin cert para el smoke

  allowed_ingress_cidrs = ["0.0.0.0/0"]

  standard_tags = {
    Project         = "example"
    Owner           = "devops@example"
    ClickupID       = "N/A"
    ClickupURL      = "https://clickup.example/t/xxx"
    Environment     = "prod"
    CostCenter      = "platform"
    Department      = "platform"
    Application     = "alb-module-test"
    ManagedByTool   = "terraform"
    CreatedBy       = "devops"
    Backup          = "none"
    Confidentiality = "public"
    ExpirationDate  = "2030-01-01"
  }
}

