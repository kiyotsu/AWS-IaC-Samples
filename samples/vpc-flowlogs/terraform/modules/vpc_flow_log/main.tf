locals {

  is_create     = var.log_destination_arn == null ? true : false
  is_s3_create  = var.log_destination_type == "s3" && local.is_create ? true : false
  is_cwl_create = var.log_destination_type == "cloud-watch-logs" && local.is_create ? true : false
  role_arn      = local.is_cwl_create ? aws_iam_role.this[0].arn : null
  destination_arn = (
    local.is_create == false ? var.log_destination_arn :
    var.log_destination_type == "s3" ? aws_s3_bucket.this[0].arn :
    var.log_destination_type == "cloud-watch-logs" ? aws_cloudwatch_log_group.this[0].arn : null
  )
}

data "aws_iam_policy_document" "dest_cloudwatchl_log_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_cloudwatch_log_group" "this" {
  count = local.is_cwl_create ? 1 : 0
  name  = "${var.prefix}-log-group"
}

resource "aws_s3_bucket" "this" {
  count         = local.is_s3_create ? 1 : 0
  bucket_prefix = "${var.prefix}-bucket"
}

resource "aws_iam_role_policy" "this" {
  count  = local.is_cwl_create ? 1 : 0
  name   = "${var.prefix}-policy"
  role   = aws_iam_role.this[0].id
  policy = data.aws_iam_policy_document.dest_cloudwatchl_log_policy.json
}

resource "aws_iam_role" "this" {
  count              = local.is_cwl_create ? 1 : 0
  name               = "${var.prefix}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_flow_log" "this" {
  iam_role_arn         = local.role_arn
  log_destination      = local.destination_arn
  log_destination_type = var.log_destination_type
  traffic_type         = var.traffic_type
  vpc_id               = var.vpc_id
}
