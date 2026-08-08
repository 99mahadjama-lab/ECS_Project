data "aws_ecr_repository" "ecr_repo" {
  name = var.repo_name
}
data "aws_ec2_managed_prefix_list" "s3" {
  name = "com.amazonaws.eu-west-2.s3"
}
