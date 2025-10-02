data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, { Name = var.name })
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-igw" })
}

# Public subnets
resource "aws_subnet" "public" {
  for_each = toset(var.public_subnets)

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  map_public_ip_on_launch = true
  availability_zone       = element(data.aws_availability_zones.available.names, index(var.public_subnets, each.value))

  tags = merge(var.tags, { Name = "${var.name}-public-${element(split("/", each.value), 0)}" })
}

# Private (app) subnets
resource "aws_subnet" "private" {
  for_each = toset(var.private_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = element(data.aws_availability_zones.available.names, index(var.private_subnets, each.value))

  tags = merge(var.tags, { Name = "${var.name}-private-${element(split("/", each.value), 0)}" })
}

# DB subnets (for RDS)
resource "aws_subnet" "db" {
  for_each = toset(var.db_subnets)

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = element(data.aws_availability_zones.available.names, index(var.db_subnets, each.value))

  tags = merge(var.tags, { Name = "${var.name}-db-${element(split("/", each.value), 0)}" })
}

# Route table for public subnets -> IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# EIP(s) and NAT Gateway(s)
resource "aws_eip" "nat" {
  count = var.nat_gateway_count
  vpc   = true

  tags = merge(var.tags, { Name = "${var.name}-nat-eip-${count.index}" })
}

resource "aws_nat_gateway" "nat" {
  count = var.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = element(values(aws_subnet.public).*.id, count.index % length(values(aws_subnet.public)))

  tags = merge(var.tags, { Name = "${var.name}-nat-${count.index}" })
}

# Private route table -> NAT
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.nat.*.id, 0)
  }

  tags = merge(var.tags, { Name = "${var.name}-private-rt" })
}

resource "aws_route_table_association" "private_assoc" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# RDS subnets route table (no internet route by default)
resource "aws_route_table" "db" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, { Name = "${var.name}-db-rt" })
}

resource "aws_route_table_association" "db_assoc" {
  for_each = aws_subnet.db

  subnet_id      = each.value.id
  route_table_id = aws_route_table.db.id
}

# S3 gateway endpoint (so private resources can access S3 without internet)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.this.id
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [aws_route_table.private.id, aws_route_table.db.id]

  tags = merge(var.tags, { Name = "${var.name}-s3-endpoint" })
}
