# Project Overview

This project demonstrates a full production-grade AWS deployment pipeline for IT Tools, an open source collection of handy developer utilities, built to show cloud and DevOps engineering skills including Terraform infrastructure as code, containerization, and CI/CD automation.

## App Demo

link

## Architecture Diagram

link

### Infrastructure Overview

| Component | Purpose |
|---|---|
| Route 53 | DNS resolution for it-tools.mahadvo.com |
| Internet Gateway | Allows public subnets to reach the internet |
| Regional NAT Gateway | Outbound internet access for private subnets (ECS tasks), auto EIP/AZ |
| VPC (10.0.0.0/24) | Isolated network for all resources, 2 AZs |
| Public Subnets (2) | Host the ALB |
| Private Subnets (2) | Host ECS Fargate tasks |
| Application Load Balancer | Terminates HTTPS (443), forwards to target group |
| Target Group | Routes traffic to ECS Fargate tasks on port 3000 |
| ACM Certificate | TLS certificate for HTTPS, validated via DNS |
| ECS Fargate Tasks | Runs the containerised IT Tools app |
| ECR | Stores the app's Docker images |
| ECR VPC Endpoint | Lets Fargate tasks pull images without going through NAT |
| CloudWatch Logs | Collects container logs |
| CloudWatch Logs VPC Endpoint | Lets Fargate tasks ship logs without going through NAT |
| S3 (state bucket) | Stores Terraform remote state |

## Project Structure

```bash
ECS_Project/
├── Dockerfile
├── docker.md
├── .github
│   ├──CICD.md
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
│   ├── bootstrap.md
│   ├── main.tf
│   ├── provider.tf
│   └── variables.tf
└── infra
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
    ├── variables.tf
    └── terraform.md
```
## Docker

The app is built with a multi-stage, non-root Dockerfile — see [docker.md](docker.md) for the full breakdown.

### Local Setup

1. Clone the repo
   `git clone <repo-url>`
2. Build the image
   `docker build -t it_tools_app .`
3. Run the container
   `docker run -d --name it-tools -p 8080:3000 it_tools_app:latest`
4. Open your browser
   `http://localhost:8080`

No environment variables required — the app runs standalone.

## Terraform

Infrastructure is provisioned across modular Terraform configs — see [terraform.md](infra/terraform.md) for the full breakdown.

## CI/CD
Four workflows handle build, scan, push, deploy, and infrastructure lifecycle end-to-end via GitHub Actions — see [CICD.md](.github/CICD.md) for the full breakdown, including prerequisites and the fetch-image-tag logic each one uses.

### CI/CD Pipelines
### CI/CD Pipelines
| Workflow | Type | Purpose |
|---|---|---|
| CI – Build, Scan & Push | CI | Builds the Docker image, scans it for vulnerabilities with Grype, then pushes it to ECR |
| CD – Deploy to ECS | CD | Fetches the current task definition, renders the new image into it, and deploys to ECS |
| Terraform Apply | CD | Applies infrastructure changes to AWS |
| Terraform Destroy | CD | Tears down AWS infrastructure, gated behind a confirmation phrase |

## Pipeline Screenshots

CI – Build, Scan & Push
Successful run showing the build, Grype vulnerability scan, and image push to ECR all passing.

Show Image

CD – Deploy to ECS
Successful run rendering the new task definition and deploying it to the ECS service.

Show Image

Terraform Apply Pipeline
Successful run showing the security scan followed by terraform apply provisioning the infrastructure.

Show Image

Terraform Destroy Pipeline — safety gate
A run where the confirmation phrase didn't match, so the destroy step was correctly skipped.

Show Image

Terraform Destroy Pipeline — successful run
A run with the correct confirmation phrase, showing terraform destroy executing successfully.

Show Image

Adjust the file paths/names to whatever you actually commit into docs/.


## Considerations

- **Terraform version**: pinned to `1.15.7` throughout — set via `hashicorp/setup-terraform@v4` in both the Apply and Destroy pipelines, matching the version used locally when the `infra/` stack was originally built. Use the same version locally to avoid state/provider drift.
- **Grype scan can fail the build on base-image CVEs.** CI is configured with `fail-build: true, severity-cutoff: critical` — any critical-severity vulnerability anywhere in the image, including unused packages pulled in by the base image, will block the push. A `tiff` CVE traced to `nginx-module-image-filter` (unused by this app) previously broke the build; removed via `RUN apk del nginx-module-image-filter` in the Dockerfile's production stage. If a future build fails on a new CVE, check whether the flagged package is actually used before assuming the app itself is affected.
- **ECS task definition has `lifecycle { ignore_changes = [task_definition] }`.** Terraform deliberately ignores changes to the task definition so that CI/CD — not Terraform — owns which image is running; running `terraform apply` won't revert a deploy made by the CD pipeline.
- **All workflows cancel in-progress runs on re-trigger** (`concurrency: cancel-in-progress: true`) — re-running Apply or Destroy mid-flight kills the previous run rather than queuing behind it.

## Future Improvements

- **Multi-environment setup** — Separate test, staging, and prod environments rather than a single deployed environment.
- **ALB access logging** — Enable access logs on the ALB to capture request-level errors and traffic patterns, currently no visibility beyond CloudWatch alarms.
- **Cost tagging & budget alerts** — Tag resources by project and configure an AWS Budget alert, since `desired_count = 2` runs constantly and incurs cost regardless of usage.
- **Separate Terraform Plan and Apply workflows** — Currently `apply.yaml` runs plan and apply together in one step. Splitting these would allow the plan output to be reviewed (and scanned) as its own gated step before a distinct Apply workflow executes the change.