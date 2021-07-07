
variable "lambda_layers" {
  description = "Additional layers to add to the worker lambda"
  type        = list(string)
  default     = []
}

variable "lambda_memory_size" {
  description = "Memory to allocate for the lambda: 128 MB to 3,008 MB, in 64 MB increments. CPU allocated relative to memory."
  type        = number
  default     = 128
}

variable "lambda_npm_7" {
  description = "Enable npm 7 on the worker lambda (installed as a layer)"
  type        = bool
  default     = false
}

variable "lambda_role" {
  type    = string
  default = null
}

variable "lambda_timeout" {
  type    = number
  default = 60
}

variable "meta_name" {
  type = string
}
