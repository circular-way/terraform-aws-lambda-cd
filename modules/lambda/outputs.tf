output "lambda" {
  value = {
    arn           = aws_lambda_function.lambda.arn
    function_name = aws_lambda_function.lambda.function_name
    last_modified = aws_lambda_function.lambda.last_modified
    role          = basename(aws_lambda_function.lambda.role)
  }

  depends_on = [
    aws_lambda_function.lambda,
    aws_iam_role_policy.iam_lambda_runtime
  ]
}
