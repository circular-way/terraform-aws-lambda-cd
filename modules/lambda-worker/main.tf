terraform {
  required_version = ">= 1"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.46.0"
    }

    time = {
      source  = "hashicorp/time"
      version = ">= 0.7.2"
    }
  }
}
