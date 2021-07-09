terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.47.0"
    }
  }

  backend "remote" {
    organization = "sellalong"

    workspaces {
      name = "terraform-aws-lambda-cd-test"
    }
  }
}

provider "aws" {
  region = "eu-west-2"
  assume_role {
    role_arn    = var.aws_provider_role_arn
    external_id = var.aws_provider_external_id
  }
}

variable "aws_provider_role_arn" {
  type    = string
  default = null
}

variable "aws_provider_external_id" {
  type    = string
  default = null
}

module "integration_test" {
  source = "./.."

  meta_name = "terraform_module_lambda_ci_int_test"

  lambda_environment_variables = {
    NODE_ENV = "production"
  }

  package_sources_path = "${path.module}/lambda_source"
  package_target_dir   = "dist"
  package_target_s3 = {
    bucket = aws_s3_bucket.integration_test.bucket
    prefix = "integration_test/"
  }

  worker_lambda_memory_size = 512
  worker_lambda_npm_7       = true

  build_commands = [
    "npm --version",
    "npm ci",
    "npm run build"
  ]

  build_environment_variables = {
    RUNNER = "integration_test"
  }

  package_target_include = ["*.js", "*.json", "build.txt"]
  package_target_exclude = ["tsconfig.json", "*-lock.json"]
}

resource "time_static" "main_integration_test_sources_updated" {
  triggers = {
    sources_hash = module.integration_test.package.s3.etag
  }
}

data "aws_lambda_invocation" "main_integration_test" {
  function_name = module.integration_test.lambda.function_name

  input = jsonencode({
    time = time_static.main_integration_test_sources_updated.rfc3339
  })
}

output "intgration_test_result" {
  value = jsondecode(data.aws_lambda_invocation.main_integration_test.result)
}

output "from_module" {
  value = {
    lambda  = module.integration_test.lambda
    package = module.integration_test.package
    worker  = module.integration_test.worker
  }
}

resource "aws_s3_bucket" "integration_test" {
  bucket_prefix = "sellalong-tf-aws-lambda-cd-"
  force_destroy = true

  versioning {
    enabled = true
  }
}
