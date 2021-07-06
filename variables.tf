variable "build_commands" {
  description = "Commands to run remotely on the worker lambda during build phase, in the directory root of $${var.package_source_path}"
  type        = list(string)
  default     = ["npm ci", "npm run build"]
}


variable "cloudwatch_logs_enable" {
  type    = bool
  default = true
}

variable "cloudwatch_logs_retention" {
  description = "Log retention in days"
  type        = number
  default     = 7
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
  description = "Existing iam role (name not arn) to allocate to the lambda at runtime"
  type        = string
  default     = null
}

variable "lambda_runtime" {
  type    = string
  default = "nodejs14.x"
}

variable "lambda_timeout" {
  type    = number
  default = 3
}

variable "meta_name" {
  description = "Name of the lambda and all resources"
  type        = string
}

variable "package_target_dir" {
  description = "Directory relative to the sources path root to package for deployment (eg: \"./dist\")"
  type        = string
  default     = "."
}

variable "package_target_s3" {
  description = "S3 bucket and key prefix for packages and artefacts"
  type = object({
    bucket = string
    prefix = string
  })
}

variable "package_sources_path" {
  description = "Deploy sources from local path to the lambda package. This or package_sources_s3 must be specified."
  type        = string
  default     = null
}

variable "package_sources_s3" {
  description = "Deploy from existing sources package in S3. This or package_sources_path must be specified."
  type = object({
    bucket     = string
    key        = string
    version_id = string
  })
  default = null
}

variable "worker_meta_name" {
  description = "Name of worker lambda and all its resources - defaults to: \"worker_$${var.meta-name}\""
  default     = null
}

variable "worker_lambda_function_name" {
  description = "Use an existing worker lambda"
  type        = string
  default     = null
}

variable "worker_lambda_layers" {
  description = "Additional lambda layers for the worker lambda"
  type        = list(string)
  default     = []
}

variable "worker_lambda_memory_size" {
  description = "Memory to allocate for the worker lambda: 128 MB to 3,008 MB, in 64 MB increments. CPU allocated relative to memory."
  type        = number
  default     = 128
}

variable "worker_lambda_role" {
  description = "Existing iam role (name not arn) to allocate to the worker lambda at runtime"
  type        = string
  default     = null
}

variable "worker_lambda_timeout" {
  type    = number
  default = 180
}
