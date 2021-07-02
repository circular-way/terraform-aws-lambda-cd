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

  meta_name            = "terraform_module_lambda_ci_int_test"
  package_sources_path = "${path.module}/lambda_source"
  package_target_s3 = {
    bucket = aws_s3_bucket.integration_test.bucket
    prefix = "integration_test/"
  }
}

resource "aws_s3_bucket" "integration_test" {
  bucket_prefix = "sellalong-tf-aws-lambda-cd-"

  versioning {
    enabled = true
  }
}
