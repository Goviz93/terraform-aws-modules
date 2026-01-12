# ─────────────────────────────────────────────────────────────────────────────
# examples/ecs-service-smoke/main.tf  (versión corregida)
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ── VPC por defecto y subnets ────────────────────────────────────────────────
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

locals {
  subnets_all         = data.aws_subnets.default_vpc_subnets.ids
  subnets_for_alb     = length(local.subnets_all) >= 2 ? slice(local.subnets_all, 0, 2) : local.subnets_all
  container_port      = 80
  service_name        = "ecs-service-smoke"
  family_name         = "ecs-service-smoke"
  logs_retention_days = 7
}

# ── Security Groups ──────────────────────────────────────────────────────────
resource "aws_security_group" "alb" {
  name        = "${local.service_name}-alb-sg"
  description = "ALB SG (HTTP in)"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.service_name}-alb-sg" }
}

resource "aws_security_group" "tasks" {
  name        = "${local.service_name}-tasks-sg"
  description = "Tasks SG (allow from ALB)"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = local.container_port
    to_port         = local.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.service_name}-tasks-sg" }
}

# ── ALB HTTP + TG ────────────────────────────────────────────────────────────
resource "aws_lb" "this" {
  name               = "${local.service_name}-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = local.subnets_for_alb
  tags               = { Name = "${local.service_name}-alb" }
}

resource "aws_lb_target_group" "app" {
  name        = "${local.service_name}-tg"
  port        = local.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    matcher             = "200-399"
  }

  tags = { Name = "${local.service_name}-tg" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ── ECS Cluster (módulo existente) ───────────────────────────────────────────
module "ecs_cluster" {
  source = "../../modules/ecs/cluster"

  name                      = "ecs-cluster-smoke"
  enable_container_insights = true

  standard_tags = {
    Project         = "platform"
    Owner           = "devops"
    ClickupID       = "CU-000"
    ClickupURL      = "https://app.clickup.com/t/CU-000"
    Environment     = "smoke"
    CostCenter      = "IT"
    Department      = "Engineering"
    Application     = "ecs-service-smoke"
    ManagedByTool   = "terraform"
    CreatedBy       = "iac"
    Backup          = "false"
    Confidentiality = "internal"
    ExpirationDate  = "2099-12-31"
  }

  tags = { Purpose = "ecs-service-smoke" }
}

# ⬇️ Obtener el ARN real del cluster (el módulo exporta name, no arn)
data "aws_ecs_cluster" "this" {
  cluster_name = module.ecs_cluster.name
}

# ── IAM para Task/Execution Role ─────────────────────────────────────────────
module "ecs_iam" {
  source = "../../modules/ecs/iam"

  name            = "ecs-service-smoke"
  enable_ecs_exec = false

  standard_tags = {
    Project         = "platform"
    Owner           = "devops"
    ClickupID       = "CU-000"
    ClickupURL      = "https://app.clickup.com/t/CU-000"
    Environment     = "smoke"
    CostCenter      = "IT"
    Department      = "Engineering"
    Application     = "ecs-service-smoke"
    ManagedByTool   = "terraform"
    CreatedBy       = "iac"
    Backup          = "false"
    Confidentiality = "internal"
    ExpirationDate  = "2099-12-31"
  }

  tags = { Purpose = "ecs-service-smoke" }
}

# ── ECS Task Definition (módulo 'task') ──────────────────────────────────────
module "ecs_task" {
  source = "../../modules/ecs/task"

  family             = local.family_name
  cpu                = 256
  memory             = 512
  task_role_arn      = module.ecs_iam.task_role_arn
  execution_role_arn = module.ecs_iam.execution_role_arn

  container_name  = "nginx"
  container_image = "nginx:stable"

  container_port_mappings = [{
    container_port = local.container_port
    protocol       = "tcp"
  }]

  container_environment = { APP_ENV = "smoke" }

  logs_enabled          = true
  logs_create_log_group = true
  logs_group_name       = "" # fallback: /ecs/${family}/${container_name}
  logs_stream_prefix    = "app"
  logs_retention_days   = local.logs_retention_days

  standard_tags = {
    Project         = "platform"
    Owner           = "devops"
    ClickupID       = "CU-000"
    ClickupURL      = "https://app.clickup.com/t/CU-000"
    Environment     = "smoke"
    CostCenter      = "IT"
    Department      = "Engineering"
    Application     = "ecs-service-smoke"
    ManagedByTool   = "terraform"
    CreatedBy       = "iac"
    Backup          = "false"
    Confidentiality = "internal"
    ExpirationDate  = "2099-12-31"
  }

  tags = { Purpose = "ecs-service-smoke" }
}

# ── ECS Service (módulo bajo prueba) ─────────────────────────────────────────
module "ecs_service" {
  source = "../../modules/ecs/service"

  name                = local.service_name
  cluster_arn         = data.aws_ecs_cluster.this.arn # ⬅️ corregido
  task_definition_arn = module.ecs_task.task_definition_arn

  subnet_ids         = local.subnets_all
  security_group_ids = [aws_security_group.tasks.id]
  assign_public_ip   = true

  enable_load_balancer              = true
  target_group_arn                  = aws_lb_target_group.app.arn
  lb_container_name                 = "nginx"
  lb_container_port                 = local.container_port
  health_check_grace_period_seconds = 60

  enable_deployment_circuit_breaker  = true
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  capacity_provider_strategy = []
  enable_autoscaling         = false

  standard_tags = {
    Project         = "platform"
    Owner           = "devops"
    ClickupID       = "CU-000"
    ClickupURL      = "https://app.clickup.com/t/CU-000"
    Environment     = "smoke"
    CostCenter      = "IT"
    Department      = "Engineering"
    Application     = "ecs-service-smoke"
    ManagedByTool   = "terraform"
    CreatedBy       = "iac"
    Backup          = "false"
    Confidentiality = "internal"
    ExpirationDate  = "2099-12-31"
  }

  tags = { Purpose = "ecs-service-smoke" }
}

# ── Salidas útiles ───────────────────────────────────────────────────────────
output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "service_name" {
  value = module.ecs_service.service_name
}

output "task_definition_arn" {
  value = module.ecs_task.task_definition_arn
}

# ── Variables del example ────────────────────────────────────────────────────
variable "region" {
  description = "AWS Region para el smoke test."
  type        = string
  default     = "us-east-1"
}

