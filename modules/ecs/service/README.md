# ECS Service (Fargate)

Módulo Terraform para crear un **ECS Service** en **AWS Fargate** con:
- Deploy controlado (rolling update, circuit breaker/rollback).
- Integración opcional con **ALB/NLB** (Target Group).
- Red `awsvpc` (subnets/SG, IP pública opcional).
- **ECS Exec** opcional.
- **Capacity Providers** (FARGATE / FARGATE_SPOT).
- **Application Auto Scaling** opcional (CPU/Mem).
- Tags corporativos obligatorios + extras.

---

## 🚀 Uso básico

```hcl
module "ecs_service" {
  source = "path/to/modules/ecs/service"

  name                = "myapp-svc"
  cluster_arn         = module.ecs_cluster.arn
  task_definition_arn = module.ecs_task.task_definition_arn

  subnet_ids         = module.vpc.app_subnet_ids
  security_group_ids = [aws_security_group.app.id]
  assign_public_ip   = false

  # ALB opcional
  enable_load_balancer               = true
  target_group_arn                   = aws_lb_target_group.app.arn
  lb_container_name                  = "myapp"
  lb_container_port                  = 80
  health_check_grace_period_seconds  = 60

  # Deploy & control
  enable_deployment_circuit_breaker  = true
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  enable_execute_command             = false

  # Capacity providers (opcional)
  capacity_provider_strategy = [
    { capacity_provider = "FARGATE",       weight = 1 },
    { capacity_provider = "FARGATE_SPOT",  weight = 1 }
  ]

  # Auto Scaling (opcional)
  enable_autoscaling        = true
  autoscaling_min_capacity  = 1
  autoscaling_max_capacity  = 3
  autoscaling_metric_type   = "cpu"   # o "memory"
  autoscaling_target_value  = 50

  standard_tags = {
    Project         = "platform"
    Owner           = "devops"
    ClickupID       = "CU-123"
    ClickupURL      = "https://app.clickup.com/t/CU-123"
    Environment     = "prod"
    CostCenter      = "IT"
    Department      = "Engineering"
    Application     = "myapp"
    ManagedByTool   = "terraform"
    CreatedBy       = "iac"
    Backup          = "false"
    Confidentiality = "internal"
    ExpirationDate  = "2099-12-31"
  }

  tags = {
    Purpose = "web"
  }
}

