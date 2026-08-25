
```bash
ECS_Project
├── Dockerfile
├── docker.md
├── .github
│   └── workflows
│       ├── app.yaml
│       ├── apply.yaml
│       ├── deploy.yaml
│       └── destroy.yaml
├── .gitignore
├── .tfsec
│   └── config.yaml
├── Dockerfile
├── docker.md
├── bootstrap
│   ├── main.tf
│   ├── provider.tf
│   └── variables.tf
└── infra
    ├── backend.tf
    ├── main.tf
    ├── modules
    │   ├── acm
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── alb
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── cloudwatch
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── ecr
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── ecs
    │   │   ├── main.tf
    │   │   ├── outputs.tf
    │   │   └── variables.tf
    │   ├── iam
    │   │   ├── main.tf
    │   │   └── outputs.tf
    │   └── vpc
    │       ├── main.tf
    │       ├── outputs.tf
    │       └── variables.tf
    ├── outputs.tf
    ├── provider.tf
    ├── terraform.md
    ├── terraform.tfvars.example
    └── variables.tf
```