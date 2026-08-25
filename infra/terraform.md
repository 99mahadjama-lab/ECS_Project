# Terraform ECSv1 — Modular AWS Infrastructure for IT Tools

## Goal

Deploy the containerised IT Tools app on AWS using modular Terraform — VPC, IAM, ACM, ALB, ECR, ECS, CloudWatch — on ECS Fargate, reachable over HTTPS, with remote state in S3 and native locking.

## Project Structure

```bash
infra/
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
├── terraform.md
├── terraform.tfvars.example
└── variables.tf
```

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

## Prerequisites

Before running this Terraform, three categories of things need to already exist:

**1. Manually created, external to any Terraform in this project**
- Route53 hosted zone for `my_domain` — read via `data "aws_route53_zone" "primary"` in the ACM module, never created or destroyed by Terraform (destroying/recreating a Terraform-owned zone rotates nameservers and breaks the registrar link)
- ECR repository (`var.repo_name`) — read via `data "aws_ecr_repository" "ecr_repo"` in the ECR module; the repo itself must be created out-of-band

**2. Always-exists AWS-managed resources (nothing to provision, just referenced)**
- S3 managed prefix list (`com.amazonaws.eu-west-2.s3`) — via `data "aws_ec2_managed_prefix_list" "s3"` in the ECR module
- `AmazonECSTaskExecutionRolePolicy` — AWS-managed IAM policy, via `data "aws_iam_policy" "ecs_task_execute_policy"` in the IAM module

**3. Provisioned separately by `bootstrap/`**
See [bootstrap.md](../bootstrap/bootstrap.md) for details.

## Values You'll Need to Replace

- `backend.tf` — S3 bucket name (`ecs-bucket-160885277387-eu-west-2-an` is specific to this AWS account; yours will differ)
- `terraform.tfvars` — `project_tag`, `my_domain` (needs its own manually-created hosted zone, per Prerequisites), `cluster_name`, `repo_name` (must already exist, per Prerequisites), `host_port`, `container_port`
- `provider.tf` — region (`eu-west-2`), if deploying elsewhere
- AWS credentials — assumed to already be configured, not set by this code
---

⬅️ Back to the [main README](../README.md) for the full project overview.


