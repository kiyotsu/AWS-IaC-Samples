data "aws_region" "current" {}

locals {
  region = var.region == null ? data.aws_region.current.name : var.region
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids
  security_group_ids = [aws_security_group.this.id]

  vpc_endpoint_type = "Interface"
  service_name      = "com.amazonaws.${local.region}.ssm"

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids
  security_group_ids = [aws_security_group.this.id]

  vpc_endpoint_type = "Interface"
  service_name      = "com.amazonaws.${local.region}.ssmmessages"

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids
  security_group_ids = [aws_security_group.this.id]

  vpc_endpoint_type = "Interface"
  service_name      = "com.amazonaws.${local.region}.ec2messages"

  private_dns_enabled = true
}

resource "aws_security_group" "this" {
  vpc_id = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  count             = length(var.subnet_cider_blocks)
  security_group_id = aws_security_group.this.id
  cidr_ipv4         = var.subnet_cider_blocks[count.index]
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}
