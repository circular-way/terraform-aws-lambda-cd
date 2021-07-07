resource "aws_lambda_function" "lambda" {
  function_name = var.meta_name
  role          = try(aws_iam_role.iam_lambda[0].arn, var.lambda_role)

  filename         = local.package_local.filename
  source_code_hash = local.package_local.source_code_hash

  s3_bucket         = local.package_s3.bucket
  s3_key            = local.package_s3.key
  s3_object_version = local.package_s3.object_version

  handler     = var.lambda_handler
  layers      = var.lambda_layers
  memory_size = var.lambda_memory_size
  runtime     = var.lambda_runtime
  timeout     = var.lambda_timeout

  dynamic "environment" {
    for_each = length(keys(var.lambda_environment_variables)) == 0 ? [] : [true]
    content {
      variables = var.lambda_environment_variables
    }
  }
}
