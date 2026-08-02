variable "project_tag" {
  type = string
}
variable "my_domain" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "public_subnet_1" {
  type = string
}
variable "public_subnet_2" {
  type = string
}
variable "private_subnet_1_CIDR" {
  type = string
}
variable "private_subnet_2_CIDR" {
  type = string
}
variable "hosted_zone" {
  type = string
}
variable "subdomain" {
  type = string
}
variable "certificate_arn" {
  type = string
}
variable "cert_validated" {
  type = any
}
variable "dev_ip" {
  type = string
}