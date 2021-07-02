variable "cloudwatch_logs_enable" {
  type    = bool
  default = true
}

variable "cloudwatch_logs_retention" {
  description = "Log retention in days"
  type        = number
  default     = 7
}


variable "lambda_environment_variables" {
  description = "A map that defines environment variables for the lambda."
  type        = map(string)
  default     = {}
}

variable "lambda_handler" {
  type    = string
  default = "main.handler"
}

variable "lambda_layers" {
  type    = list(string)
  default = []
}

variable "lambda_memory_size" {
  description = "Memory to allocate for the lambda: 128 MB to 3,008 MB, in 64 MB increments. CPU allocated relative to memory."
  type        = number
  default     = 128
}

variable "lambda_role" {
  description = "Existing iam role arn to allocate to the lambda at runtime."
  type        = string
  default     = null
}

variable "lambda_runtime" {
  type = string
}

variable "lambda_timeout" {
  type    = number
  default = 3
}

variable "meta_name" {
  description = "Name of the lambda and all resources"
  type        = string
}

variable "package_s3" {
  description = "Deploy from existing package archive (zip) in S3"
  type = object({
    bucket     = string
    key        = string
    version_id = string
  })
  default = null
}

variable "package_target_s3" {
  description = "Deploy package sources to S3 first, requires package_local_path to be specified."
  type = object({
    bucket = string
    prefix = string
  })
  default = null
}

variable "package_local_path" {
  description = "Deploy from lambda package from all files within a local directory."
  type        = string
  default     = null
}
