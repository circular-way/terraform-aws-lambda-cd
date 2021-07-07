resource "aws_cloudwatch_log_group" "cloudwatch_lambda_runtime" {
  count             = var.cloudwatch_logs_enable ? 1 : 0
  name              = "/aws/lambda/${var.meta_name}"
  retention_in_days = var.cloudwatch_logs_retention
}
