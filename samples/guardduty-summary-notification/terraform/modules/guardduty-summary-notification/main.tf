locals {
  name_prefix = "${var.system_name}-${var.env}"
}

resource "aws_sns_topic" "guardduty_summary" {
  name = "${local.name_prefix}-topic"
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "for_function" {
  name               = "${local.name_prefix}-function-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy" "for_function" {
  name = "${local.name_prefix}-function-policy"
  role = aws_iam_role.for_function.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["bedrock:*"]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = ["sns:Publish"]
        Effect   = "Allow"
        Resource = aws_sns_topic.guardduty_summary.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "AWSLambdaBasicExecutionRole" {
  role       = aws_iam_role.for_function.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_dir  = "../source"
  output_path = "../source/lambda_function.zip"
}

resource "aws_lambda_function" "guardduty_summary_notification" {
  function_name    = "${local.name_prefix}-function"
  role             = aws_iam_role.for_function.arn
  filename         = data.archive_file.lambda_function.output_path
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  package_type     = "Zip"
  timeout          = 60
  source_code_hash = filebase64sha256(data.archive_file.lambda_function.output_path)
  publish          = true

  environment {
    variables = {
      SNS_TOPIC = aws_sns_topic.guardduty_summary.arn
    }
  }
}

resource "aws_cloudwatch_event_rule" "guardduty_finding" {
  name = "${local.name_prefix}-finding-rule"

  event_pattern = jsonencode({
    source = [
      "aws.guardduty"
    ]
    detail-type = [
      "GuardDuty Finding"
    ]
    detail = {
      severity = [
        { "numeric" : [">", var.severity_threshold] }
      ]
    }
  })
}

resource "aws_lambda_permission" "allow_invoke" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.guardduty_summary_notification.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_finding.arn
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule = aws_cloudwatch_event_rule.guardduty_finding.name
  arn  = aws_lambda_function.guardduty_summary_notification.arn
}
