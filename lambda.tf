module "lambda" {
  source = "./modules/lambda"

  cloudwatch_logs_enable       = var.cloudwatch_logs_enable
  cloudwatch_logs_retention    = var.cloudwatch_logs_retention
  lambda_environment_variables = var.lambda_environment_variables
  lambda_handler               = var.lambda_handler
  lambda_layers                = var.lambda_layers
  lambda_memory_size           = var.lambda_memory_size
  lambda_role                  = var.lambda_role
  lambda_runtime               = var.lambda_runtime
  lambda_timeout               = var.lambda_timeout
  meta_name                    = var.meta_name

  package_s3 = local.worker_invoke_result.package_s3
}
