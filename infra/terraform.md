# Terraform ECSv1 — Modular AWS Infrastructure for IT Tools

## Goal

Deploy the containerised IT Tools app on AWS using modular Terraform — VPC, IAM, ACM, ALB, ECR, ECS, CloudWatch — on ECS Fargate, reachable over HTTPS, with remote state in S3 and native locking.

## Project Structure
.
├── backend.tf
├── main.tf
├── modules
│   ├── acm
│   ├── alb
│   ├── cloudwatch
│   ├── ecr
│   ├── ecs
│   ├── iam
│   └── vpc
├── outputs.tf
├── provider.tf
├── terraform.tfvars.example
└── variables.tf

## Architecture Overview

Region: eu-west-2. Domain: mahadvo.com → it-tools.mahadvo.com. Flow: client → ALB (443 HTTPS) → target group (3000) → ECS Fargate task. Modules: VPC, IAM, ACM, ALB, ECR, ECS, CloudWatch — no separate Route53 module, that lives inside ACM (zone lookup/cert validation) and ALB (the alias record).

## Key Points Per Module

- **Remote state**: S3 backend with `use_lockfile = true` — native locking, no DynamoDB needed.
- **VPC**: /24 VPC, 2 public + 2 private /26 subnets across 2 AZs. One regional NAT gateway (`availability_mode = "regional"` — auto EIP, not tied to one AZ/subnet).
- **IAM**: creates `ecs_task_execute_role`, attaches AWS-managed `AmazonECSTaskExecutionRolePolicy`.
- **ECR**: looks up an existing repo + the S3 prefix list via `data` (repo isn't created by this code).
- **ECS**: two security groups (task + endpoint) linked via explicit `security_group_rule` resources to avoid a cycle. Same rule covers app traffic and ALB health checks (same port). Four VPC endpoints: ECR API, ECR DKR, Logs, S3. `runtime_platform` set to `X86_64` (GitHub Actions runners are x86_64, not ARM). Service points at `.arn`, not `.family`, to avoid state drift.
- **CloudWatch**: log group + CPU/memory alarms (≥80%, 2×180s) — no SNS wired up yet, so no actual notifications.
- **ALB**: 443 open to world, health-checks `/health` on 3000, HTTPS listener depends on ACM validation, Route53 alias record routes traffic.
- **ACM**: hosted zone is manually created and only ever read via `data` — never managed by Terraform — because destroying/recreating a Terraform-owned zone rotates nameservers and breaks the registrar link. Sibling modules (ACM ↔ ALB) can't reference each other directly, so values route through root.

## Values You'll Need to Replace

- `backend.tf` — S3 bucket name (yours will differ)
- `terraform.tfvars` (copy from `terraform.tfvars.example`) — `project_tag`, `my_domain` (needs its own manually-created hosted zone), `cluster_name`, `repo_name` (must already exist)
- `provider.tf` — region, if not eu-west-2
- AWS credentials — assumed to already be configured, not set by this code

## Known Gotchas

- **Stuck lock**: if a run doesn't exit cleanly, `terraform force-unlock <lock-id>`.
- **.tfvars not loading**: only `terraform.tfvars` or `*.auto.tfvars` auto-load; anything else needs `-var-file`.