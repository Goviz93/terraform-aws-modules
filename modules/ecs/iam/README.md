# ECS IAM Module

Crea los **roles IAM** necesarios para ejecutar servicios ECS (Fargate):

- **Task Role (rol de la app):** permisos que usa **tu contenedor** en runtime (acceso a Secrets, S3, etc.).
- **Execution Role (rol del agente):** permisos que usa **ECS/Fargate** al **arrancar** la tarea (pull de imagen ECR, logs a CloudWatch, etc.).
- (Opcional) Permisos mínimos para **ECS Exec** en el **Task Role**.

## Requisitos
- Terraform `>= 1.6`
- AWS provider `>= 5.0`

## Qué crea
- `aws_iam_role.task` + *attachments* de **managed** e **inline** policies.
- `aws_iam_role.execution` + `AmazonECSTaskExecutionRolePolicy` + *attachments* extra (si se especifican).

## Inputs (resumen)
- `name` *(string, req.)*: prefijo para nombrar roles.
- `enable_ecs_exec` *(bool, default `true`)*: añade permisos **ssmmessages** al **Task Role**.
- `task_managed_policy_arns` *(list(string))*: ARNs de policies **managed** para el **Task Role**.
- `task_inline_policies` *(map(string))*: políticas **inline** (JSON string) para el **Task Role**.
- `execution_managed_policy_arns` *(list(string))*: ARNs extra para el **Execution Role**.
- `execution_inline_policies` *(map(string))*: políticas **inline** (JSON string) para el **Execution Role**.
- `standard_tags` *(object tipado corporativo, req.)*
- `tags` *(map(string), default `{}`)*

## Outputs
- `task_role_name`, `task_role_arn`
- `execution_role_name`, `execution_role_arn`

## Uso básico
```hcl
module "ecs_iam" {
  source = "git::ssh://gitlab.com/yourorg/platform-modules-aws.git//modules/ecs/iam?ref=v0.1.0"

  name            = "myapp-prod"
  enable_ecs_exec = true

  # Sin políticas extra (ejemplo mínimo)
  task_managed_policy_arns      = []
  task_inline_policies          = {}
  execution_managed_policy_arns = []
  execution_inline_policies     = {}

  standard_tags = var.standard_tags
}

