#######################################
# Title   : VPC Flow Log Sample
# Date    : 2024-05-17
# Version : 0.01
#######################################
terraform {
  required_version = ">= 1.8.2"

  required_providers {
    aws = {
      version = "~> 5.47.0"
      source  = "hashicorp/aws"
    }
  }
}

#######################################
# VPC-related resource
#######################################
resource "aws_vpc" "sample" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "sample" {
  vpc_id            = aws_vpc.sample.id
  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.0.0/24"
}

resource "aws_internet_gateway" "sample" {
  vpc_id = aws_vpc.sample.id
}

resource "aws_route_table" "sample" {
  vpc_id = aws_vpc.sample.id
}

resource "aws_route" "sample" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = aws_route_table.sample.id
  gateway_id             = aws_internet_gateway.sample.id
}

resource "aws_route_table_association" "sample" {
  subnet_id      = aws_subnet.sample.id
  route_table_id = aws_route_table.sample.id
}

#######################################
# EC2-related resource
#######################################
resource "aws_instance" "main" {
  ami                         = "ami-02a405b3302affc24"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.sample.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
}

resource "aws_security_group" "allow_ssh" {
  name   = "allow_ssh"
  vpc_id = aws_vpc.sample.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_instance_connect" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "3.112.23.0/29" # used for EC2 Instance Connect
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

#######################################
# VPC-Flowlogs
#######################################
module "sample_vpc_flow_log" {
  source = "./modules/vpc_flow_log"
  prefix = "sample"

  # Target VPC
  vpc_id = aws_vpc.sample.id

  # output to cloud-watch-logs
  log_destination_type = "cloud-watch-logs"

  # output to s3
  #    log_destination_type = "s3"
}
