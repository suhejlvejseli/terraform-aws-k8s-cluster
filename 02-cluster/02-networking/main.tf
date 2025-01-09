locals {
  project = "terraform-aws-k8s-cluster"

  default_tags = {
    Project = local.project
    Label   = "Thesis"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = merge({
    Name = "${local.project}-main-VPC"
  }, local.default_tags)
}

resource "aws_subnet" "cluster_subnet" {
  count             = 1
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, count.index + 2)
  availability_zone = element(data.aws_availability_zones.available.names, count.index)

  tags = merge({
    Name = "k8s-cluster-subnet"
    Tier = "Public"
  }, local.default_tags)
}

# resource "aws_subnet" "private" {
#   count             = 2
#   vpc_id            = aws_vpc.main.id
#   cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 10, count.index + 2)
#   availability_zone = element(data.aws_availability_zones.available.names, count.index)

#   tags = merge({
#     Name = "pivate-subnet-${count.index + 1}"
#     Tier = "Private"
#   }, local.default_tags)
# }

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge({
    Name = "${local.project}-internet-gateway"
  }, local.default_tags)
}

# resource "aws_eip" "nat_gtw_eip" {
#   domain = "vpc"

#   tags = merge({
#     Name = "${local.project}-nat-gtw-eip"
#   }, local.default_tags)
# }

# resource "aws_nat_gateway" "main" {
#   allocation_id = aws_eip.nat_gtw_eip.id
#   subnet_id     = aws_subnet.public[0].id

#   tags = merge({
#     Name = "${local.project}-nat-gtw"
#   }, local.default_tags)
# }

# public route table, route internet traffic to internet gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge({
    Name = "${local.project}-public-route-table"
  }, local.default_tags)
}

# associate public route table with public subnet
resource "aws_route_table_association" "public_association" {
  count          = length(aws_subnet.cluster_subnet)
  subnet_id      = aws_subnet.cluster_subnet[count.index].id
  route_table_id = aws_route_table.public.id
}

# private route table
# resource "aws_route_table" "private" {
#   vpc_id = aws_vpc.main.id

#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.main.id
#   }

#   tags = merge({
#     Name = "${local.project}-private-route-table"
#   }, local.default_tags)
# }

# associate private route table with private subnet
# resource "aws_route_table_association" "private_association" {
#   count          = length(aws_subnet.private)
#   subnet_id      = aws_subnet.private[count.index].id
#   route_table_id = aws_route_table.private.id
# }