locals {
  worker_invoke_result = jsondecode(
    data.aws_lambda_invocation.worker_invoke_build.result
  )
}

# sleep 10s after worker_lambda_s3_access policy created due to iam eventual consistency
resource "time_sleep" "worker_invoke_iam_s3_access" {
  depends_on = [aws_iam_role_policy.worker_lambda_s3_access]

  create_duration = "10s"
}

data "aws_lambda_invocation" "worker_invoke_build" {
  function_name = var.worker_lambda_function_name == null ? module.worker[0].lambda_worker.function_name : var.worker_lambda_function_name

  # workaround see: https://github.com/hashicorp/terraform-provider-aws/issues/4746
  input = jsonencode({
    time          = time_static.package_sources_updated.rfc3339
    source        = "io.sellalong.lambda-cd-worker"
    "detail-type" = "BUILD"
    detail = {
      commands    = var.build_commands
      environment = var.build_environment_variables
      s3 = {
        sources = {
          bucket    = local.package_sources.bucket
          key       = local.package_sources.key
          versionId = local.package_sources.version_id
        }

        target = {
          bucket  = var.package_target_s3.bucket
          exclude = var.package_target_exclude
          dir     = var.package_target_dir
          include = var.package_target_include
          prefix  = var.package_target_s3.prefix
        }
      }
    }
  })

  depends_on = [
    time_sleep.worker_invoke_iam_s3_access
  ]
}
