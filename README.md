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
    │   ├── alb
    │   ├── cloudwatch
    │   ├── ecr
    │   ├── ecs
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

### CI/CD Pipelines
| Workflow | Type | Purpose |
|---|---|---|
| CI – Build, Scan & Push | CI | Builds the Docker image, scans it for vulnerabilities with Grype, then pushes it to ECR |
| CD – Deploy to ECS | CD | Fetches the current task definition, renders the new image into it, and deploys to ECS |
| Terraform Apply | CD | Applies infrastructure changes to AWS |
| Terraform Destroy | CD | Tears down AWS infrastructure, gated behind a confirmation phrase |
