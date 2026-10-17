data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "${var.project_name}-${var.environment}-vpc" }
}


resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project_name}-${var.environment}-igw" }
}

# Public subnets — hold the ALB. 
resource "aws_subnet" "public" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = { Name = "${var.project_name}-${var.environment}-public-${count.index}" }
}

# Private subnets — hold Fargate tasks 
resource "aws_subnet" "private" {
  count             = var.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + var.az_count)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = { Name = "${var.project_name}-${var.environment}-private-${count.index}" }
}

# Isolated subnets — hold RDS 
resource "aws_subnet" "isolated" {
  count             = var.az_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 2 * var.az_count)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = { Name = "${var.project_name}-${var.environment}-isolated-${count.index}" }
}

resource "aws_eip" "name" {
  count = var.az_count
  domain = "vpc"
}

resource "aws_nat_gateway" "name" {
  count = var.az_count
  allocation_id = aws_eip.id
  subnet_id = aws_subnet.public[count.index].id
  connectivity_type = "private"

  tags = { 
    Name = "${var.project_name}-nat-${count.index}" 
  }

  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = { Name = "${var.project_name}-${var.environment}-public-rt" }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.name[count.index].id
  }

  tags = { Name = "${var.project_name}-${var.environment}-private-rt" }
}

resource "aws_route_table_association" "public" {
  count          = var.az_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = var.az_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# NAT gateway intentionally omitted for the LocalStack build — Fargate tasks in
# private subnets reach Secrets Manager/ECR through LocalStack's local network,
# not real internet egress. The real-AWS build (separate directory) adds a NAT
# gateway so private-subnet tasks can reach Paystack/Firebase over the internet.
