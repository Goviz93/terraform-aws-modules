#############################################
# VPC core: VPC, IGW, subnets, routes, NAT #
#############################################

# ── VPC ──────────────────────────────────────────────────────────────────────
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(local.default_tags, { Name = "${local.name_prefix}-vpc" })
}

# Internet Gateway
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.default_tags, { Name = "${local.name_prefix}-igw" })
}

# ── Subnets (public/app/db) ───────────────────────────────────────────────────

# Public subnets
resource "aws_subnet" "public" {
  for_each = { for s in local.public_subnets : s.name => s }

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.cidr
  availability_zone       = each.value.az
  map_public_ip_on_launch = true

  tags = each.value.tags
}

# App subnets (privadas)
resource "aws_subnet" "app" {
  for_each = { for s in local.app_subnets : s.name => s }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = each.value.tags
}

# DB subnets (privadas)
resource "aws_subnet" "db" {
  for_each = { for s in local.db_subnets : s.name => s }

  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  tags = each.value.tags
}

# ── Route tables & associations ───────────────────────────────────────────────

# Public RT (compartida)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  tags   = merge(local.default_tags, { Name = "${local.name_prefix}-rt-public" })
}

# Default route a Internet via IGW
resource "aws_route" "public_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

# Asociar todas las subnets públicas a la RT pública
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# App RTs (una por subnet para enrutar a su NAT correspondiente)
resource "aws_route_table" "app" {
  for_each = aws_subnet.app
  vpc_id   = aws_vpc.this.id
  tags     = merge(local.default_tags, { Name = "${local.name_prefix}-rt-app-${each.value.availability_zone}" })
}

# DB RTs (una por subnet; sin ruta 0.0.0.0/0)
resource "aws_route_table" "db" {
  for_each = aws_subnet.db
  vpc_id   = aws_vpc.this.id
  tags     = merge(local.default_tags, { Name = "${local.name_prefix}-rt-db-${each.value.availability_zone}" })
}

# Asociaciones
resource "aws_route_table_association" "app" {
  for_each       = aws_subnet.app
  subnet_id      = each.value.id
  route_table_id = aws_route_table.app[each.key].id
}

resource "aws_route_table_association" "db" {
  for_each       = aws_subnet.db
  subnet_id      = each.value.id
  route_table_id = aws_route_table.db[each.key].id
}

# ── NAT Gateways (condicional) ────────────────────────────────────────────────

# Primer subnet pública (para NAT compartido)
locals {
  first_public_subnet_id     = try(aws_subnet.public["${local.name_prefix}-pub-0"].id, element(values(aws_subnet.public), 0).id)
  public_subnet_ids_by_az    = { for k, s in aws_subnet.public : s.availability_zone => s.id }
}

# EIPs para NAT (por AZ o compartido)
resource "aws_eip" "nat" {
  for_each = local.nat_per_az ? local.public_subnet_ids_by_az : { "shared" = local.first_public_subnet_id }

  domain = "vpc"
  tags   = merge(local.default_tags, { Name = local.nat_per_az ? "${local.name_prefix}-eip-nat-${each.key}" : "${local.name_prefix}-eip-nat-shared" })
}

# NAT Gateways
resource "aws_nat_gateway" "this" {
  for_each = local.nat_per_az ? local.public_subnet_ids_by_az : { "shared" = local.first_public_subnet_id }

  allocation_id = local.nat_per_az ? aws_eip.nat[each.key].id : aws_eip.nat["shared"].id
  subnet_id     = each.value
  tags          = merge(local.default_tags, { Name = local.nat_per_az ? "${local.name_prefix}-nat-${each.key}" : "${local.name_prefix}-nat-shared" })

  depends_on = [aws_internet_gateway.this]
}

# Ruta por defecto en RTs de App hacia el NAT correspondiente
resource "aws_route" "app_nat" {
  for_each = var.enable_nat ? aws_route_table.app : {}

  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = local.nat_per_az ? aws_nat_gateway.this[aws_subnet.app[each.key].availability_zone].id : aws_nat_gateway.this["shared"].id
}

# ── VPC Endpoints ─────────────────────────────────────────────────────────────

# SG para Interface Endpoints (HTTPS desde la VPC)
resource "aws_security_group" "endpoints" {
  name        = "${local.name_prefix}-vpce-sg"
  description = "Security group for Interface Endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-vpce-sg" })
}

# Resolver nombres de servicios para VPCE (evita usar data.aws_region.current.name)
data "aws_vpc_endpoint_service" "iface" {
  for_each     = toset(local.interface_endpoint_services)
  service      = each.value
  service_type = "Interface"
}

data "aws_vpc_endpoint_service" "s3" {
  count        = length(local.gateway_endpoint_services) > 0 ? 1 : 0
  service      = "s3"
  service_type = "Gateway"
}

# Interface Endpoints (en subnets App)
resource "aws_vpc_endpoint" "interface" {
  for_each = toset(local.interface_endpoint_services)

  vpc_id              = aws_vpc.this.id
  service_name        = data.aws_vpc_endpoint_service.iface[each.value].service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for s in aws_subnet.app : s.id]
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.endpoints.id]

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-vpce-${each.value}" })
}

# Gateway Endpoint para S3 (adjunto a RTs de App y DB)
resource "aws_vpc_endpoint" "s3" {
  count = length(local.gateway_endpoint_services) > 0 ? 1 : 0

  vpc_id            = aws_vpc.this.id
  service_name      = data.aws_vpc_endpoint_service.s3[0].service_name
  vpc_endpoint_type = "Gateway"
  route_table_ids   = concat([for rt in aws_route_table.app : rt.id], [for rt in aws_route_table.db : rt.id])

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-vpce-s3" })
}

# ── VPC Flow Logs (CloudWatch) ────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "flow" {
  count             = var.enable_flow_logs ? 1 : 0
  name              = local.flow_logs_group_name
  retention_in_days = var.flow_logs_retention_days
  tags              = local.default_tags
}

resource "aws_iam_role" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${local.name_prefix}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "vpc-flow-logs.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
  tags = local.default_tags
}

resource "aws_iam_role_policy" "flow_logs" {
  count = var.enable_flow_logs ? 1 : 0
  name  = "${local.name_prefix}-vpc-flow-logs-policy"
  role  = aws_iam_role.flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      Resource = "*"
    }]
  })
}

resource "aws_flow_log" "this" {
  count                = var.enable_flow_logs ? 1 : 0
  vpc_id               = aws_vpc.this.id
  traffic_type         = "ALL"

  log_destination_type = "cloud-watch-logs"
  log_destination      = aws_cloudwatch_log_group.flow[0].arn
  iam_role_arn         = aws_iam_role.flow_logs[0].arn

  tags = merge(local.default_tags, { Name = "${local.name_prefix}-flow-logs" })
}

