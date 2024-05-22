#######################################
# Title   : Using a session manager in a private VPC Sample
# Date    : 2024-05-21
# Version : 0.01
#######################################

#######################################
# VPC-related resource
#######################################
resource "aws_vpc" "sample" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "sample" {
  vpc_id            = aws_vpc.sample.id
  availability_zone = "ap-northeast-1a"
  cidr_block        = "10.0.0.0/24"
}

#######################################
# EC2-related resource
#######################################
resource "aws_instance" "sample" {
  ami                    = "ami-02a405b3302affc24"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.sample.id
  vpc_security_group_ids = [aws_security_group.sample.id]
  iam_instance_profile   = aws_iam_instance_profile.sample.id
}

resource "aws_security_group" "sample" {
  vpc_id = aws_vpc.sample.id
}

resource "aws_vpc_security_group_egress_rule" "sample" {
  security_group_id = aws_security_group.sample.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

data "aws_iam_policy_document" "sample" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sample" {
  assume_role_policy = data.aws_iam_policy_document.sample.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

resource "aws_iam_instance_profile" "sample" {
  role = aws_iam_role.sample.name
}

#######################################
# Setup VPC Endpoints for Session Manager
#######################################
module "vpc_endpoints_for_session_manager" {
  source              = "./modules/setup_sessionmanager"
  vpc_id              = aws_vpc.sample.id
  subnet_ids          = [aws_subnet.sample.id]
  subnet_cider_blocks = [aws_subnet.sample.cidr_block]
}
