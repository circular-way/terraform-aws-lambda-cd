module "lambda_worker" {
  source = "../lambda"

  lambda_environment_variables = {
    # use keep-alive on AWS service connections
    AWS_NODEJS_CONNECTION_REUSE_ENABLED = 1
    CI                                  = true
  }

  # TODO support more runtimes for worker
  lambda_runtime = "nodejs14.x"

  lambda_layers = concat(
    [aws_lambda_layer_version.lambda_worker_vendor.arn],
    var.lambda_npm_7 ? [aws_lambda_layer_version.lambda_worker_vendor_npm7[0].arn] : [],
    coalesce(var.lambda_layers, []),
  )

  lambda_memory_size = var.lambda_memory_size
  lambda_role        = var.lambda_role
  lambda_timeout     = var.lambda_timeout
  meta_name          = var.meta_name
  package_local_path = "${path.module}/sources/worker"
}

resource "aws_lambda_layer_version" "lambda_worker_vendor" {
  layer_name       = "${var.meta_name}-vendor"
  filename         = "${path.module}/vendor/vendor.zip"
  source_code_hash = filebase64sha256("${path.module}/vendor/vendor.zip")
}

resource "aws_lambda_layer_version" "lambda_worker_vendor_npm7" {
  count               = var.lambda_npm_7 ? 1 : 0
  compatible_runtimes = ["nodejs14.x"]
  layer_name          = "${var.meta_name}-vendor-npm-7"
  filename            = "${path.module}/vendor-npm-7/vendor-npm.zip"
  source_code_hash    = filebase64sha256("${path.module}/vendor-npm-7/vendor-npm.zip")
}
