locals {
  name_prefix = "${var.system}-${var.env}"
}

resource "aws_cloudwatch_event_rule" "guardduty_finding" {
  name = "guardduty-finding-rule"

  event_pattern = jsonencode({
    source = [
      "aws.guardduty"
    ]
    detail-type = [
      "GuardDuty Finding"
    ]
  })
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule = aws_cloudwatch_event_rule.guardduty_finding.name
  arn  = aws_lambda_function.handler.arn
}

resource "aws_sns_topic" "guardduty_notify" {
  name = "guardduty-notify-summary-topic"
}

data "archive_file" "handler" {
  type        = "zip"
  source_dir  = "../source"
  output_path = "../source/handler.zip"
}

resource "aws_lambda_function" "handler" {
  function_name = "${local.name_prefix}-handler"
  role          = aws_iam_role.handler.arn

  filename     = data.archive_file.handler.output_path
  handler      = "lambda_handler.lambda_handler"
  runtime      = "python3.12"
  package_type = "Zip"
  timeout      = 60

  source_code_hash = filebase64sha256(data.archive_file.handler.output_path)
  publish          = true
  environment {
    variables = {
      SNS_TOPIC = aws_sns_topic.guardduty_notify.arn
    }
  }
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_finding.arn
}

data "aws_iam_policy_document" "assume_lambda" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "handler" {
  name = "${local.name_prefix}-handler-policy"
  role = aws_iam_role.handler.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "bedrock:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "sns:Publish",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role" "handler" {
  name               = "${local.name_prefix}-handler-role"
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

resource "aws_iam_role_policy_attachment" "AWSLambdaBasicExecutionRole" {
  role       = aws_iam_role.handler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
