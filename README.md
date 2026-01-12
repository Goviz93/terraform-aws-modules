# Terraform Modules

Repository of **reusable Terraform modules**.  
These modules act as building blocks to provision and manage infrastructure across different environments (AWS, On-prem, etc.).

---

## 📂 Structure

```bash
└── modules/
    ├── vpc/
    │   ├── main.tf         # Recursos: VPC, subnets, IGW, NAT, RTs, VPC Endpoints
    │   ├── variables.tf    # Entradas (CIDRs, AZs, flags, tags)
    │   ├── outputs.tf      # Salidas (vpc_id, subnets, rt_ids, endpoints, etc.)
    │   ├── locals.tf       # Nombres, tags por defecto.
    │   └── README.md
    │
    ├── alb/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── README.md
    │
    ├── ecr/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── README.md
    │
    ├── ecs/
    │   ├── cluster/      # ECS (Fargate) Cluster + capacity providers
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   ├── outputs.tf
    │   │   └── README.md
    │   ├── iam/          # Roles/policies: task & execution
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   ├── outputs.tf
    │   │   └── README.md
    │   ├── task/         # Task Definition (containers, cpu/mem, logs, secrets)
    │   │   ├── main.tf
    │   │   ├── variables.tf
    │   │   ├── outputs.tf
    │   │   └── README.md
    │   └── service/      # Service (Fargate), autoscaling, ALB attach
    │       ├── main.tf
    │       ├── variables.tf
    │       ├── outputs.tf
    │       └── README.md
    │
    ├── cloudwatch-logs/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── README.md
    │
    ├── rds/
    │   ├── main.tf
    │   ├── variables.tf
    │   ├── outputs.tf
    │   └── README.md
    │
    └── networking-sg/
        ├── main.tf
        ├── variables.tf
        ├── outputs.tf
        └── README.md
```

---

## 🚀 Usage

Example of how to consume a module from infra-live or an application project:

```bash

module "vpc" {
  source = "../modules/vpc"

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

```

---

## 🔖 Versioning

- Each major change must be released as a semantic version tag (v1.0.0, v1.1.0, etc.).
- Do not use main directly in production. Create a new branch and create your new module.
- Environments (infra-live) must always consume stable versions.

---

## 🧪 Testing

```bash
terraform fmt -check
terraform validate
tflint
```


