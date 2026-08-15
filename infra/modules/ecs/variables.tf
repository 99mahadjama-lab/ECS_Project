variable "project_tag" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "private_subnet_1_CIDR" {
  type = string
}
variable "private_subnet_2_CIDR" {
  type = string
}
variable "private_route" {
  type = string
}
variable "alb_sg" {
  type = string
}
variable "nat_gateway_id" {
  type = string
}
variable "cpu" {
  type = number
  default = 1024
}
variable "memory" {
  type = number
  default = 2048
}
variable "host_port" {
  type = number
}
variable "container_port" {
  type = number
}
variable "execution_role_arn" {
  type = string
}
variable "private_subnet_1" {
  type = string
}
variable "private_subnet_2" {
  type = string
}
variable "target_group_arn" {
  type = string
}
variable "log_group" {
  type = string
}
variable "cluster_name" {
  type = string
}
variable "repo_url" {
  type = string
}
variable "latest_tag" {
  type = string
}
variable "prefix_list" {
  type = string
}
