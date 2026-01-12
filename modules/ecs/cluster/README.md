# ECS Cluster Module

Crea un **ECS Cluster (Fargate/Fargate Spot)** con **Container Insights** opcional y, si se desea, un **namespace privado de Cloud Map** para service discovery.

## Requisitos
- Terraform `>= 1.6`
- AWS provider `>= 5.0`

## Qué crea
- `aws_ecs_cluster` con (opcional) **Container Insights**
- `aws_ecs_cluster_capacity_providers` con estrategia por defecto
- (Opcional) `aws_service_discovery_private_dns_namespace` (Cloud Map)

## Inputs (resumen)
- `name` *(string, req)*: nombre/prefijo del cluster.
- `enable_container_insights` *(bool, default `true`)*.
- `capacity_providers` *(list(string), default `["FARGATE","FARGATE_SPOT"]`)*.
- `capacity_strategy` *(object)*:  
  - `fargate_weight` *(number)*  
  - `fargate_spot_weight` *(number)*  
  - `base` *(number)* — **mínimo** de tareas en FARGATE.
- `enable_cloud_map` *(bool, default `false`)*.
- `cloud_map_namespace_name` *(string, req si `enable_cloud_map=true`)*.
- `vpc_id` *(string, req si `enable_cloud_map=true`)*.
- `standard_tags` *(object tipado corporativo, req)*.
- `tags` *(map(string), default `{}`)*.

## Outputs
- `cluster_id`, `cluster_arn`, `cluster_name`
- `capacity_providers`
- `default_capacity_provider_strategy`
- `cloud_map_namespace_id`, `cloud_map_namespace_arn` *(o `null`)*

## Uso básico
```hcl
module "ecs_cluster" {
  source = "git::ssh://gitlab.com/yourorg/platform-modules-aws.git//modules/ecs/cluster?ref=v0.1.0"

  name                      = "shared-prod"
  enable_container_insights = true
  capacity_providers        = ["FARGATE","FARGATE_SPOT"]
  capacity_strategy = {
    fargate_weight      = 1
    fargate_spot_weight = 3
    base                = 1
  }

  # Cloud Map (opcional)
  enable_cloud_map          = false
  cloud_map_namespace_name  = ""
  vpc_id                    = ""

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

