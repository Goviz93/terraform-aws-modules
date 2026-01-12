terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source = "../../modules/vpc"

  name     = "example-prod"
  vpc_cidr = "10.10.0.0/16"
  azs      = local.azs

  public_cidrs = ["10.10.0.0/20", "10.10.16.0/20"]
  app_cidrs    = ["10.10.32.0/20", "10.10.48.0/20"]
  db_cidrs     = ["10.10.64.0/24", "10.10.65.0/24"]

  standard_tags = {
    Project         = "example"
    Owner           = "devops@example"
    ClickupID       = "N/A"
    ClickupURL      = "https://clickup.example/t/xxx"
    Environment     = "prod"
    CostCenter      = "platform"
    Department      = "platform"
    Application     = "vpc-module-test"
    ManagedByTool   = "terraform"
    CreatedBy       = "devops"
    Backup          = "none"
    Confidentiality = "public"
    ExpirationDate  = "2030-01-01"
  }
}

