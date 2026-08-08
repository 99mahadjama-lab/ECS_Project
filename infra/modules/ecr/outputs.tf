output "repo_url" {
  value = data.aws_ecr_repository.ecr_repo.repository_url
}
output "repo_arn" {
  value = data.aws_ecr_repository.ecr_repo.arn
}
output "prefix_list" {
  value = data.aws_ec2_managed_prefix_list.s3
}