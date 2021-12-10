##################################################################
# Network Elements Creation:
# All network elements creation for a VPC with 3
# Layers: Public, Application and Data subnets
# Also including a NAT Gateway for outbound communication.
##################################################################
########### VPC Creation ###########
resource "aws_vpc" "main" {
  cidr_block = var.vpc_attrs.cidr
  
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
      var.common_tags,
      {
        Name = var.vpc_attrs.name
      }
  )
}
########### Flow Log Creation ###########
## Flow Log
resource "aws_flow_log" "main" {
  iam_role_arn    = aws_iam_role.main.arn
  log_destination = aws_cloudwatch_log_group.main.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}
## Cloudwatch Group
resource "aws_cloudwatch_log_group" "main" {
  name = "/vpc/flowlog"
}
## IAM Role
resource "aws_iam_role" "main" {
  name = "vpc-flowlog"

  assume_role_policy = file("${path.module}/iam_files/vpc_flowlog_assume.json")
}
## IAM Policy
resource "aws_iam_role_policy" "main" {
  name = "vpc-flowlog"
  role = aws_iam_role.main.id

  policy = file("${path.module}/iam_files/vpc_flowlog_policy.json")
}
########### Default Route Table Clearing ###########
resource "aws_default_route_table" "main" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route = []

  tags = merge(
      var.common_tags,
      {
        Name = "default-rt"
      }
  )
}
########### Default Security Group Clearing ###########
resource "aws_default_security_group" "main" {
  vpc_id = aws_vpc.main.id
  tags = merge(
      var.common_tags,
      {
        Name = "default-sg"
      }
  )
}
########### Internet Gateway Creation ###########
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
      var.common_tags,
      {
        Name = "main-igw"
      }
  )
}
########### Default DHCP Options Creation ###########
resource "aws_default_vpc_dhcp_options" "main" {
  tags = merge(
      var.common_tags,
      {
        Name = "main-dhcp"
      }
  )
}
##################################################################
########### Subnets Creation ###########
### Public
resource "aws_subnet" "public_sn" {
  count = length(var.pub_sn_attrs)

  vpc_id     = aws_vpc.main.id
  cidr_block = var.pub_sn_attrs.cidr_list[count.index]

  availability_zone = "${var.region}${var.azs[count.index]}"

  tags = merge(
      var.common_tags,
      {
        Name = "${var.pub_sn_attrs.name}-${count.index + 1}"
      }
  )
}
### Private/App
resource "aws_subnet" "private_sn" {
  count = length(var.priv_sn_attrs)

  vpc_id     = aws_vpc.main.id
  cidr_block = var.priv_sn_attrs.cidr_list[count.index]

  availability_zone = "${var.region}${var.azs[count.index]}"

  tags = merge(
      var.common_tags,
      {
        Name = "${var.priv_sn_attrs.name}-${count.index + 1}"
      }
  )
}
### Data
resource "aws_subnet" "data_sn" {
  count = length(var.data_sn_attrs)

  vpc_id     = aws_vpc.main.id
  cidr_block = var.data_sn_attrs.cidr_list[count.index]

  availability_zone = "${var.region}${var.azs[count.index]}"

  tags = merge(
      var.common_tags,
      {
        Name = "${var.data_sn_attrs.name}-${count.index + 1}"
      }
  )
}
##################################################################
########### NAT Gateway Creation ###########
### Public IP Allocation
resource "aws_eip" "natgw" {
  vpc = true
  depends_on                = [aws_internet_gateway.main]

  tags = merge(
      var.common_tags,
      {
        Name = "natgw-public-ip"
      }
  )
}
### Public IP Allocation
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.natgw.id
  subnet_id     = aws_subnet.public_sn[0].id

  tags = merge(
      var.common_tags,
      {
        Name = "main-natgw"
      }
  )

  depends_on = [aws_internet_gateway.main]
}
##################################################################
########### Routing Table Creation ###########
### Public Routing Table + Association
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
      var.common_tags,
      {
        Name = "public-rt"
      }
  )
}
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public_sn)
  subnet_id      = aws_subnet.public_sn[count.index].id
  route_table_id = aws_route_table.public.id
}
### Private Routing Table + Association
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(
      var.common_tags,
      {
        Name = "private-rt"
      }
  )
}
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private_sn)
  subnet_id      = aws_subnet.private_sn[count.index].id
  route_table_id = aws_route_table.private.id
}
### Data Routing Table + Association
resource "aws_route_table" "data" {
  vpc_id = aws_vpc.main.id

  route = []

  tags = merge(
      var.common_tags,
      {
        Name = "data-rt"
      }
  )
}
resource "aws_route_table_association" "data" {
  count = length(aws_subnet.data_sn)
  subnet_id      = aws_subnet.data_sn[count.index].id
  route_table_id = aws_route_table.data.id
}