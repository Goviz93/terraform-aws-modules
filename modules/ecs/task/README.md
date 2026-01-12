# ECS Task Definition (Fargate)

Módulo Terraform para definir una **ECS Task Definition** en **AWS Fargate** con soporte para:

- Contenedor principal (imagen, variables, secretos, puertos).
- Logs a CloudWatch (opcional, con creación del Log Group).
- Almacenamiento efímero configurable (21–200 GiB).
- Montajes EFS opcionales.
- Tags corporativos obligatorios + tags adicionales.

---

## 📦 Uso básico

```hcl
module "ecs_task" {
  source = "../modules/ecs/task"

  family            = "myapp-prod"
  cpu               = 256
  memory            = 512
  task_role_arn     = module.ecs_iam.task_role_arn
  execution_role_arn = module.ecs_iam.execution_role_arn

  container_name  = "myapp"
  container_image = "nginx:stable"

  container_port_mappings = [{
    container_port = 80
    protocol       = "tcp"
  }]

  container_environment = {
    APP_ENV = "prod"
  }

  logs_enabled          = true
  logs_create_log_group = true

  standard_tags = {
    Project         = "Demo"
    Owner           = "DevOps"
    ClickupID       = "CU-123"
    ClickupURL      = "https://app.clickup.com/t/CU-123"
    Environment     = "prod"
    CostCenter      = "IT"
    Department      = "Engineering"
    Application     = "myapp"
    ManagedByTool   = "terraform"
    CreatedBy       = "iac"
    Backup          = "true"
    Confidentiality = "internal"
    ExpirationDate  = "2099-12-31"
  }
}
