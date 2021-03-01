/**
 * Copyright (c) 2020 TypeFox GmbH. All rights reserved.
 * Licensed under the MIT License. See License-MIT.txt in the project root for license information.
 */

# ref: https://docs.aws.amazon.com/eks/latest/userguide/create-public-private-vpc.html

locals {
  cluster_name      = "gitpod-cluster"
  number_of_subnets = length(data.aws_availability_zones.gitpod.zone_ids)
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc
resource "aws_vpc" "gitpod" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "gitpod-vpc"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zone
data "aws_availability_zones" "gitpod" {
  state = "available"
}



#
# Public Subnets
#

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet
resource "aws_subnet" "public" {
  count                           = local.number_of_subnets
  vpc_id                          = aws_vpc.gitpod.id
  availability_zone               = data.aws_availability_zones.gitpod.names[count.index]
  cidr_block                      = "10.0.${count.index}.0/24"
  assign_ipv6_address_on_creation = false
  map_public_ip_on_launch         = true

  tags = {
    "Name"                                      = "gitpod-public-subnet-${data.aws_availability_zones.gitpod.names[count.index]}"
    "kubernetes.io/cluster/${var.cluster.name}" = "shared"
    "kubernetes.io/role/elb"                    = 1
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.gitpod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public.id
  }

  tags = {
    Name = "gitpod-rt-public-subnets"
  }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
resource "aws_route_table_association" "public" {
  count          = local.number_of_subnets
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway
resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.gitpod.id

  tags = {
    Name = "gitpod-internet-gateway"
  }
}

# # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip
# resource "aws_eip" "public" {
#   count = local.number_of_subnets
#   vpc   = true

#   tags = {
#     "Name" = "gitpod-eip-${data.aws_availability_zones.gitpod.names[count.index]}"
#   }
# }

# # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway
# resource "aws_nat_gateway" "public" {
#   count         = local.number_of_subnets
#   allocation_id = aws_eip.public[count.index].id
#   subnet_id     = aws_subnet.public[count.index].id

#   tags = {
#     "Name" = "gitpod-nat-gw-${data.aws_availability_zones.gitpod.names[count.index]}"
#   }
# }


# #
# # Private Subnets
# #

# # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet
# resource "aws_subnet" "private" {
#   count                           = local.number_of_subnets
#   vpc_id                          = aws_vpc.gitpod.id
#   availability_zone               = data.aws_availability_zones.gitpod.names[count.index]
#   cidr_block                      = "10.0.${count.index + local.number_of_subnets}.0/24"
#   assign_ipv6_address_on_creation = false
#   map_public_ip_on_launch         = false

#   tags = {
#     Name                                        = "gitpod-private-subnet-${data.aws_availability_zones.gitpod.names[count.index]}"
#     "kubernetes.io/cluster/${var.cluster.name}" = "shared"
#     "kubernetes.io/role/internal-elb"           = 1
#   }
# }

# # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table
# resource "aws_route_table" "private" {
#   count  = local.number_of_subnets
#   vpc_id = aws_vpc.gitpod.id

#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.public[count.index].id
#   }

#   tags = {
#     Name = "gitpod-rt-${data.aws_availability_zones.gitpod.names[count.index]}"
#   }
# }

# # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association
# resource "aws_route_table_association" "private" {
#   count          = local.number_of_subnets
#   subnet_id      = aws_subnet.private[count.index].id
#   route_table_id = aws_route_table.private[count.index].id
# }
