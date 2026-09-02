locals {
  subnets = {
    priv1 = {
        name                 = "Private_1"
        cidr_block           = "10.0.0.0/26"
        availability_zone    = "eu-west-2a"
    }

    priv2 = {
        name                 = "Private_2"
        cidr_block           = "10.0.0.64/26"
        availability_zone    = "eu-west-2b"
    }

    pub1 = {
        name                 = "Public_1"
        cidr_block           = "10.0.0.128/26"
        availability_zone    = "eu-west-2a"
    }
    
    pub2 = {
        name                 = "Public_2"
        cidr_block           = "10.0.0.192/26"
        availability_zone    = "eu-west-2b"
    }
  }
}
locals {
  associations = {
    priv_A1 = {
        name                 = "Private_Association_1"
        subnet_id            = aws_subnet.Subnets["priv1"].id
        route_table_id       = aws_route_table.Private_Route.id
    }
    priv_A2 = {
        name                 = "Private_Association_2"
        subnet_id            = aws_subnet.Subnets["priv2"].id
        route_table_id       = aws_route_table.Private_Route.id
    }
    pub_A1 = {
        name                 = "Public_Association_1"
        subnet_id            = aws_subnet.Subnets["pub1"].id
        route_table_id       = aws_route_table.Public_Route.id
    }
    pub_A2 = {
        name                 = "Public_Association_2"
        subnet_id            = aws_subnet.Subnets["pub2"].id
        route_table_id       = aws_route_table.Public_Route.id
    }
  }
}