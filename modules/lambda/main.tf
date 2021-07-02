terraform {
  required_version = ">= 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.46.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = ">= 2.2.0"
    }
  }
}
