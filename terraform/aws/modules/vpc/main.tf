locals {
  azs = data.aws_availability_zones.available.names
}

data "aws_availability_zones" "available" {}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge({
    Name = var.name
  }, var.tags)
}

# Internet Gateway for public subnets
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = merge({
    Name = "${var.name}-igw"
  }, var.tags)
}

# Public subnets
resource "aws_subnet" "public" {
  count                   = var.public_subnet_count
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = local.azs[count.index % length(local.azs)]

  tags = merge({
    Name = "${var.name}-public-${count.index + 1}",
    Tier = "public"
  }, var.tags)
}

# NAT EIPs (one per NAT gateway)
resource "aws_eip" "nat" {
  count = var.nat_subnet_count

  domain = "vpc"

  tags = merge({
    Name = "${var.name}-nat-eip-${count.index + 1}"
  }, var.tags)
}

# NAT Gateways in selected public subnets
resource "aws_nat_gateway" "this" {
  count = var.nat_subnet_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index % length(aws_subnet.public)].id

  depends_on = [aws_internet_gateway.igw]

  tags = merge({
    Name = "${var.name}-nat-${count.index + 1}"
  }, var.tags)
}

# Private (no nat/igw) subnets
resource "aws_subnet" "private" {
  count             = var.private_subnet_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, var.public_subnet_count + count.index)
  availability_zone = local.azs[count.index % length(local.azs)]

  tags = merge({
    Name = "${var.name}-private-${count.index + 1}",
    Tier = "private"
  }, var.tags)
}

# NAT Subnets (these are 'application' subnets that route via NAT Gateway)
resource "aws_subnet" "nat" {
  count             = var.nat_subnet_count
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, var.public_subnet_count + var.private_subnet_count + count.index)
  availability_zone = local.azs[count.index % length(local.azs)]

  tags = merge({
    Name = "${var.name}-nat-${count.index + 1}",
    Tier = "nat"
  }, var.tags)
}

# Route table for public subnets -> IGW
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge({
    Name = "${var.name}-public-rt"
  }, var.tags)
}

resource "aws_route_table_association" "public_assoc" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_rt.id
}

# Route tables for NAT subnets (these will be private subnets that use NAT gateway)
resource "aws_route_table" "nat_rt" {
  count  = var.nat_subnet_count
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this[count.index].id
  }

  tags = merge({
    Name = "${var.name}-nat-rt-${count.index + 1}"
  }, var.tags)
}

resource "aws_route_table_association" "nat_assoc" {
  count          = length(aws_subnet.nat)
  subnet_id      = aws_subnet.nat[count.index].id
  route_table_id = aws_route_table.nat_rt[count.index % length(aws_route_table.nat_rt)].id
}

# Route table for private subnets (no internet access)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.this.id

  tags = merge({
    Name = "${var.name}-private-rt"
  }, var.tags)
}

resource "aws_route_table_association" "private_assoc" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_rt.id
}
