resource "aws_iam_role" "iam_lambda" {
  count = var.lambda_role == null ? 1 : 0
  name  = "lambda_${var.meta_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowLambda"
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "iam_lambda_runtime" {
  count = var.lambda_role == null ? 1 : 0
  name  = "lambda_runtime"
  role  = aws_iam_role.iam_lambda[0].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [for v in [
      var.cloudwatch_logs_enable ? {
        Sid    = "AllowCloudwatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudwatch_lambda_runtime[0].arn}:*"
      } : null
    ] : v if v != null]
  })
}
