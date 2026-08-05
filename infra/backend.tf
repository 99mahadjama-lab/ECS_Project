terraform {
  backend "s3" {
    bucket = "ecs-bucket-160885277387-eu-west-2-an"
    key    = "it_tools/terraform.tfstate"
    region = "eu-west-2"
    use_lockfile = true
  }
}
