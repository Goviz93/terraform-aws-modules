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

module "ecs_cluster" {
  source = "../../modules/ecs/cluster"

  name                      = "ecs-smoke-prod"
  enable_container_insights = true

  # Deja los defaults:
  # capacity_providers = ["FARGATE","FARGATE_SPOT"]
  # capacity_strategy  = { fargate_weight=1, fargate_spot_weight=0, base=1 }

  enable_cloud_map         = false
  cloud_map_namespace_name = ""
  vpc_id                   = ""

  standard_tags = {
    Project         = "example"
    Owner           = "devops@example"
    ClickupID       = "N/A"
    ClickupURL      = "https://clickup.example/t/xxx"
    Environment     = "prod"
    CostCenter      = "platform"
    Department      = "platform"
    Application     = "ecs-cluster"
    ManagedByTool   = "terraform"
    CreatedBy       = "devops"
    Backup          = "none"
    Confidentiality = "public"
    ExpirationDate  = "2030-01-01"
  }
}

