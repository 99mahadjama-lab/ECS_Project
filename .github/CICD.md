# CI/CD — GitHub Actions Workflows

## Goal

Four `workflow_dispatch`-triggered (plus one `workflow_run`-chained) pipelines that build, scan, push, deploy, provision, and tear down the IT Tools stack — all authenticating to AWS via OIDC, no long-lived keys.

## Workflows

### CI – Build, Scan & Push (`app.yaml`)

Manually triggered. Builds the Docker image, scans it with Grype (`anchore/scan-action@v7`, `fail-build: true`, `severity-cutoff: critical`), logs into ECR via OIDC, then tags and pushes:

```bash
docker tag $IMAGE_NAME:$IMAGE_TAG $REGISTRY/$REPO:prod-$IMAGE_TAG
docker push $REGISTRY/$REPO:prod-$IMAGE_TAG
```

`IMAGE_TAG` is `github.sha` — every pushed image is tagged `prod-<full commit sha>`.

**Prerequisites**
- Secret: `ECR_PUSH_ROLE_ARN` — the OIDC role ARN this workflow assumes to push to ECR (created in `bootstrap/`)
- Hardcoded env: `AWS_REGION` (`eu-west-2`), `IMAGE_NAME` (`it-tools`)

---

### CD – Deploy to ECS (`deploy.yaml`)

Triggered automatically via `workflow_run` when CI completes successfully on `main` (`if: github.event.workflow_run.conclusion == 'success'`). Fetches the live task definition, renders the new image into it, and deploys:

```bash
aws ecs describe-task-definition \
  --task-definition ${{ env.TASK_DEF }} \
  --query taskDefinition > task-definition.json
```

then `amazon-ecs-render-task-definition` swaps in `${{ secrets.IMAGE_URI_PREFIX }}:prod-${{ env.IMAGE_TAG }}` for the named container, and `amazon-ecs-deploy-task-definition` deploys it, waiting up to 15s for service stability.

**Prerequisites**
- Secrets: `TF_OPS_ROLE_ARN` (OIDC role assumed for the ECS API calls and deploy), `IMAGE_URI_PREFIX` (the ECR registry/repo prefix the image lives at)
- Hardcoded env: `AWS_REGION`, `CLUSTER` (`IT-Tools-Cluster`), `CONTAINER` (`IT-Tools-Container`), `SERVICE` (`IT-Tools_cluster_service`), `TASK_DEF` (`IT-Tools-TD`)

---

### Terraform Apply Pipeline (`apply.yaml`)

Manually triggered. Runs a Terraform security scan (`triat/terraform-security-scan@v3`), then pulls the most recently *pushed* `prod-` tagged image straight from ECR:

```bash
echo "image_tag=$(aws ecr describe-images --repository-name ${{ env.ECR_REPO }} |
jq -r '[.imageDetails[] | select(.imageTags[]|startswith("prod-"))]|
sort_by(.imagePushedAt)|last|.imageTags[]|
select(startswith("prod-"))')" >> "$GITHUB_OUTPUT"
```

Writes `terraform.tfvars` from a secret at runtime, then `terraform init` → `validate` → `apply --auto-approve`, passing the pulled tag in as `-var="latest_tag=..."`.

**Prerequisites**
- Secrets: `TF_OPS_ROLE_ARN` (OIDC role for `terraform apply`), `TF_VARS` (full contents written straight into `terraform.tfvars` — the file never exists in the repo)
- Hardcoded env: `AWS_REGION`, `ECR_REPO` (`it-tools-repo`)

---

### Terraform Destroy Pipeline (`destroy.yaml`)

Manually triggered, gated behind a typed input (`confirm: "Confirm Destroy"`). Two jobs, mutually exclusive on that input:
- `cancel` runs if the phrase doesn't match — just writes a message to the job summary, no AWS calls made
- `destroy` runs if it matches, and pulls the tag **currently deployed on ECS** (not ECR's latest) as the value to destroy against:

```bash
echo "image_tag=$(aws ecs describe-task-definition \
--task-definition $(aws ecs describe-services \
--cluster ${{ env.CLUSTER }} --services ${{ env.SERVICE }} \
--query 'services[0].taskDefinition' --output text) \
--query 'taskDefinition.containerDefinitions[0].image' \
--output json | jq -r 'split(":") | last')" >> "$GITHUB_OUTPUT"
```

Note this is a different source of truth from Apply — Apply asks ECR "what's the latest pushed image," Destroy asks ECS "what's actually running right now." Then same `terraform.tfvars`-from-secret + `init` → `validate` → `destroy --auto-approve` pattern.

**Prerequisites**
- Secrets: `TF_OPS_ROLE_ARN`, `TF_VARS`
- Hardcoded env: `AWS_REGION`, `ECR_REPO`, `CLUSTER`, `CONTAINER`, `SERVICE`
- Manual input at trigger time: exact string `Confirm Destroy`

## Known Gotchas

- **CI is manual-only.** `app.yaml` triggers on `workflow_dispatch` only — no image is built/scanned/pushed automatically on push.
- **`IMAGE_TAG` in `deploy.yaml` uses `github.sha`, not `github.event.workflow_run.head_sha`.** In a `workflow_run` context, `github.sha` reflects the latest commit on the branch when CD runs, not necessarily the exact commit CI built — the two can drift if commits land in between. `github.event.workflow_run.head_sha` would pin it exactly. Hasn't caused issues in practice since both are manually dispatched off `main`.
- **Apply and Destroy resolve "the image tag" from two different sources** — Apply from ECR's push history, Destroy from ECS's live task definition — worth keeping in mind if the two ever disagree.
- **Destroy's confirmation gate is a typed string checked in workflow logic**, not a GitHub environment protection rule — it works (see pipeline screenshots) but isn't backed by GitHub's built-in required-reviewers/environment gates.
- **`terraform.tfvars` is written from a single secret (`TF_VARS`) at runtime** in both `apply.yaml` and `destroy.yaml` — never committed, only materializes inside the CI runner.