output "VPC_ID" {
  value = aws_vpc.IT-Tools_VPC.id
}
output "Private_Subnet_1" {
  value = aws_subnet.Private_Subnet_1.id
}
output "Private_Subnet_2" {
  value = aws_subnet.Private_Subnet_2.id
}
output "Public_Subnet_1" {
  value = aws_subnet.Public_Subnet_1.id
}
output "Public_Subnet_2" {
  value = aws_subnet.Public_Subnet_2.id
}
output "Private_Route" {
  value = aws_route_table.Private_Route.id
}
output "Private_Subnet_1_CIDR" {
  value = aws_subnet.Private_Subnet_1.cidr_block
}
output "Private_Subnet_2_CIDR" {
  value = aws_subnet.Private_Subnet_2.cidr_block
}
output "nat_gateway_id" {
  value = aws_nat_gateway.IT-Tools_NGW.id
}