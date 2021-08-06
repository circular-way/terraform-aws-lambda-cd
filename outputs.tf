output "lambda" {
  description = "Outputs a map with the built lambda's `arn`, `function_name`, `last_modified`, and `role`"
  value = {
    arn           = var.lambda_create ? module.lambda[0].lambda.arn : null
    function_name = var.lambda_create ? module.lambda[0].lambda.function_name : null
    last_modified = var.lambda_create ? module.lambda[0].lambda.last_modified : null
    role          = var.lambda_create ? module.lambda[0].lambda.role : null
  }
}

output "package" {
  description = "Outputs a map with the built package's `build_time`, `logs`, and `s3` location"
  value = {
    build_time = local.worker_invoke_result.build_time
    logs       = local.worker_invoke_result.logs
    s3         = local.worker_invoke_result.package_s3
  }
}

output "worker" {
  description = "Outputs a map with the worker lambda's `function_name`"
  value = {
    function_name = var.worker_lambda_function_name != null ? var.worker_lambda_function_name : module.worker[0].lambda_worker.function_name
  }
}
