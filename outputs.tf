output "lambda" {
  value = {
    arn           = module.lambda.lambda.arn
    function_name = module.lambda.lambda.function_name
    last_modified = module.lambda.lambda.last_modified
    role          = module.lambda.lambda.role
  }
}

output "package" {
  value = {
    build_time = local.worker_invoke_result.build_time
    logs       = local.worker_invoke_result.logs
    s3         = local.worker_invoke_result.package_s3
  }
}

output "worker" {
  value = {
    function_name = var.worker_lambda_function_name != null ? var.worker_lambda_function_name : module.worker[0].lambda_worker.function_name
  }
}
