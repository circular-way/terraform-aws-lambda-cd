/**
 * ## Usage:
 *
 * ```hcl
 * module "my_lambda" {
 *   source  = "sellalong/lambda-cd/aws"
 *   version = "1.0.0"
 *
 *   meta_name            = "my_lambda"
 *   package_sources_path = "${path.module}/lambda_source"
 *   package_target_dir   = "dist"
 *
 *   # S3 bucket with versioning required for storage of package artefacts
 *   package_target_s3 = {
 *     bucket = "my_package_s3_bucket"
 *     prefix = "my_lambda/"
 *   }
 *
 *   # Consider allocating more memory/timeout to the worker lambda, as builds may take a while. More memory = more CPU
 *   worker_lambda_memory_size = 512
 *   worker_lambda_timeout     = 300
 *
 *   # Can use npm v7 if desired for build
 *   worker_lambda_npm_7 = true
 *
 *   # Customise build commands (defaults below)
 *   build_commands = [
 *     "npm ci",
 *     "npm run build"
 *   ]
 * }
```
 */

terraform {
  required_version = ">= 1"

  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.2.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.46.0"
    }

    external = {
      source  = "hashicorp/external"
      version = "2.1.0"
    }

    time = {
      source  = "hashicorp/time"
      version = ">= 0.7.2"
    }
  }
}
