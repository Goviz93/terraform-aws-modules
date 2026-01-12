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

module "ecs_iam" {
  source = "../../modules/ecs/iam"

  name            = "ecs-iam-smoke-prod"
  enable_ecs_exec = true # agrega permisos SSM mínimos al Task Role

  # Sin políticas extra para el smoke
  task_managed_policy_arns      = []
  task_inline_policies          = {}
  execution_managed_policy_arns = []
  execution_inline_policies     = {}

  standard_tags = {
    Project         = "example"
    Owner           = "devops@example"
    ClickupID       = "N/A"
    ClickupURL      = "https://clickup.example/t/xxx"
    Environment     = "prod"
    CostCenter      = "platform"
    Department      = "platform"
    Application     = "ecs-iam"
    ManagedByTool   = "terraform"
    CreatedBy       = "devops"
    Backup          = "none"
    Confidentiality = "public"
    ExpirationDate  = "2030-01-01"
  }
  tags = {}
}

