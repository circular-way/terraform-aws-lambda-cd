module "worker" {
  count  = var.worker_lambda_function_name == null ? 1 : 0
  source = "./modules/lambda-worker"

  lambda_layers      = var.worker_lambda_layers
  lambda_memory_size = var.worker_lambda_memory_size
  lambda_role        = var.worker_lambda_role
  lambda_timeout     = var.worker_lambda_timeout
  meta_name          = coalesce(var.worker_lambda_function_name, "worker_${var.meta_name}")
}

resource "aws_iam_role_policy" "lambda_worker_s3_access" {
  name = "lambda_worker_s3_access"
  role = module.worker[0].lambda_worker.role
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [for v in [
      {
        Sid    = "AllowS3AccessPackageTarget"
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:Put*"
        ]
        Resource = "arn:aws:s3:::${var.package_target_s3.bucket}/${var.package_target_s3.prefix}*"
      },

      var.package_sources_s3 != null ? {
        Sid    = "AllowS3AccessSources"
        Effect = "Allow"
        Action = [
          "s3:Get*",
        ]
        Resource = "arn:aws:s3:::${var.package_sources_s3.bucket}/${var.package_sources_s3.key}"
      } : null
    ] : v if v != null]
  })
}
