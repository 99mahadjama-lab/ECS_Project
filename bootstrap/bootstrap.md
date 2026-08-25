# Bootstrap — One-Time AWS Setup for Terraform & CI/CD

## Goal

Give GitHub Actions the AWS access it needs (OIDC, IAM roles) and stand up the Terraform state backend, before the main `infra/` stack is ever run.

## What It Creates

- **OIDC provider** for `token.actions.githubusercontent.com`, so GitHub Actions can authenticate to AWS without long-lived access keys
- **`ecr_push` IAM role** — assumed via OIDC, scoped to pushing images to ECR
- **`tf_ops` IAM role** — assumed via OIDC, scoped to running `terraform apply`/`destroy` (EC2, ECS, ECR, ALB, ACM, logs, CloudWatch, Route53, IAM, plus scoped KMS and S3 state-bucket access)
- **S3 state bucket** (`ecs-bucket-<accountId>-<region>-an`) with public access blocked, used as the backend for the main `infra/` stack

## Prerequisites

- AWS credentials configured locally — this is run manually from your own machine, never through CI (avoids the chicken-and-egg problem of CI needing the roles this creates before it exists)
- State for bootstrap itself is local, not remote — there's no backend to point to until this runs
- A gitignored `terraform.tfvars` supplying `aws_acc_arn`, `region`, `github_repo`, `branch`, `test_branch`, `ecr_repo`, `project_name`, `Environment`, `accountId`

## Run Order

Bootstrap runs once, before `infra/` is applied for the first time — but not everything it creates carries the same weight:

- **The S3 state bucket is a hard dependency.** `infra/backend.tf` points at it directly, and `terraform init` fails outright if the bucket doesn't already exist — this holds whether you run `infra/` manually or through CI/CD.
- **The OIDC provider and IAM roles (`ecr_push`, `tf_ops`) are only for the pipelines.** They're what GitHub Actions assumes to push images and run Terraform. Running `infra/` manually with your own AWS credentials doesn't touch them at all.