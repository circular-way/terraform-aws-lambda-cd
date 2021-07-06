# sleep 10s after lambda_worker_s3_access policy created due to iam eventual consistency
resource "time_sleep" "iam_lambda_worker_s3_access" {
  depends_on = [aws_iam_role_policy.lambda_worker_s3_access]

  create_duration = "10s"
}

data "aws_lambda_invocation" "build" {
  function_name = var.worker_lambda_function_name == null ? module.worker[0].lambda_worker.function_name : var.worker_lambda_function_name

  # workaround see: https://github.com/hashicorp/terraform-provider-aws/issues/4746
  input = jsonencode({
    time          = timestamp()
    source        = "io.sellalong.lambda-cd-worker"
    "detail-type" = "BUILD"
    detail = {
      commands = var.build_commands
      s3 = {
        sources = {
          bucket    = local.package_sources.bucket
          key       = local.package_sources.key
          versionId = local.package_sources.version_id
        }

        target = {
          bucket = var.package_target_s3.bucket
          dir    = var.package_target_dir
          prefix = var.package_target_s3.prefix
        }
      }
    }
  })

  depends_on = [
    time_sleep.iam_lambda_worker_s3_access
  ]
}
