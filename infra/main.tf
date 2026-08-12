#Calling VPC Module
module "VPC_Module" {
  source                    = "./modules/vpc"
  project_tag               = var.project_tag
}
#Calling IAM Module
module "IAM_Module" {
  source                    = "./modules/iam"
}
# Calling ACM Module
module "ACM_Module" {
  source                    = "./modules/acm"
  project_tag               = var.project_tag
  subdomain                 = module.ALB_Module.subdomain
  my_domain                 = var.my_domain
}
#Calling ALB Module
module "ALB_Module" {
  source                    = "./modules/alb"
  project_tag               = var.project_tag
  my_domain                 = var.my_domain
  dev_ip                    = var.dev_ip
  vpc_id                    = module.VPC_Module.VPC_ID
  public_subnet_1           = module.VPC_Module.Public_Subnet_1
  public_subnet_2           = module.VPC_Module.Public_Subnet_2
  private_subnet_1_CIDR     = module.VPC_Module.Private_Subnet_1_CIDR
  private_subnet_2_CIDR     = module.VPC_Module.Private_Subnet_2_CIDR
  hosted_zone               = module.ACM_Module.Hosted_Zone.id
  subdomain                 = module.ACM_Module.Subdomain
  certificate_arn           = module.ACM_Module.certificate_arn
  cert_validated            = module.ACM_Module.cert_validated
}
#Calling ECR Module
module "ECR_Module" {
  source                    = "./modules/ecr"
  repo_name                 = var.repo_name
}
#Calling ECS Module
module "ECS_Module" {
  source = "./modules/ecs"
  project_tag               = var.project_tag
  cluster_name              = var.cluster_name
  vpc_id                    = module.VPC_Module.VPC_ID
  alb_sg                    = module.ALB_Module.alb_sg
  nat_gateway_id            = module.VPC_Module.nat_gateway_id
  execution_role_arn        = module.IAM_Module.ecs_task_execute_role_arn
  private_subnet_1          = module.VPC_Module.Private_Subnet_1
  private_subnet_2          = module.VPC_Module.Private_Subnet_2
  target_group_arn          = module.ALB_Module.target_group_arn 
  private_subnet_1_CIDR     = module.VPC_Module.Private_Subnet_1_CIDR
  private_subnet_2_CIDR     = module.VPC_Module.Private_Subnet_2_CIDR
  prefix_list               = module.ECR_Module.prefix_list.id
  private_route             = module.VPC_Module.Private_Route
  log_group                 = module.CloudWatch_Module.log_group.id
  repo_url                  = module.ECR_Module.repo_url
  latest_tag                = var.latest_tag
  depends_on                = [ module.ALB_Module , module.ECR_Module ]
}
#Cloudwatch
module "CloudWatch_Module" {
  source                    = "./modules/cloudwatch"
  project_tag               = var.project_tag
}