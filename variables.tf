variable "build_commands" {
  description = "Commands to run remotely on the worker lambda during build phase, in the directory root of `$${var.package_source_path}`"
  type        = list(string)
  default     = ["npm ci", "npm run build"]
}

variable "build_environment_variables" {
  description = "A map that defines environment variables to use in the build process while building the lambda in the worker."
  type        = map(string)
  default     = {}
}

variable "cloudwatch_logs_enable" {
  description = "Enable logging to cloudwatch logs for the built lambda"
  type        = bool
  default     = true
}

variable "cloudwatch_logs_retention" {
  description = "Log retention in days"
  type        = number
  default     = 7
}

variable "lambda_environment_variables" {
  description = "A map that defines environment variables for the built lambda."
  type        = map(string)
  default     = {}
}

variable "lambda_handler" {
  description = "Handler spec for the built lambda"
  type        = string
  default     = "main.handler"
}

variable "lambda_layers" {
  description = "Lambda layers for the built lambda"
  type        = list(string)
  default     = []
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
  description = "Runtime to use for the built lambda"
  type        = string
  default     = "nodejs14.x"
}

variable "lambda_timeout" {
  description = "Timeout in seconds for the runtime of the built lambda"
  type        = number
  default     = 3
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

variable "package_target_include" {
  description = "Files/directories relative to `$${var.package_target_dir}` to include in the package zip (zip compatible wildcards/pattern matching accepted, see: https://linux.die.net/man/1/zip)"
  type        = list(string)
  default     = ["."]
}

variable "package_target_exclude" {
  description = "Files/directories relative to `$${var.package_target_dir}` to exclude from the package zip (zip compatible wildcards/pattern matching accepted, see: https://linux.die.net/man/1/zip)"
  type        = list(string)
  default     = []
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

variable "worker_lambda_npm_7" {
  description = "Enable npm 7 on the worker lambda (installed as a layer)"
  type        = bool
  default     = false
}

variable "worker_lambda_role" {
  description = "Existing iam role (name not arn) to allocate to the worker lambda at runtime"
  type        = string
  default     = null
}

variable "worker_lambda_timeout" {
  description = "Timeout in seconds for the runtime of an invocation in the worker lambda"
  type        = number
  default     = 180
}
