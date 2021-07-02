output "lambda" {
  value = {
    arn           = aws_lambda_function.this.arn
    function_name = aws_lambda_function.this.function_name
    last_modified = aws_lambda_function.this.last_modified
    role          = basename(aws_lambda_function.this.role)
  }

  depends_on = [
    aws_lambda_function.this,
    aws_iam_role_policy.lambda_runtime
  ]
}
