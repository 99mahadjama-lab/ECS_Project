output "repo_url" {
  value = data.aws_ecr_repository.ecr_repo.repository_url
}
output "repo_arn" {
  value = data.aws_ecr_repository.ecr_repo.arn
}