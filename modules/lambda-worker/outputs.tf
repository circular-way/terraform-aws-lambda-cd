output "lambda_worker" {
  value = {
    arn           = module.lambda_worker.lambda.arn
    function_name = module.lambda_worker.lambda.function_name
    last_modified = module.lambda_worker.lambda.last_modified
    role          = module.lambda_worker.lambda.role
  }
}
