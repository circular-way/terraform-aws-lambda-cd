variable "sources_path" {
  description = "Local path to package file(s) into the target zip"
  type        = string
}

variable "target_exclude" {
  description = "File(s) to exclude from the package (zip compatible wildcards/pattern matching accepted, see: https://linux.die.net/man/1/zip)"
  type        = list(string)
  default     = []
}

variable "target_include" {
  description = "File(s) to include in the package - defaults to all files (zip compatible wildcards/pattern matching accepted, see: https://linux.die.net/man/1/zip)"
  type        = list(string)
  default     = ["."]
}

variable "target_path" {
  description = "Local path to the target archive"
  type        = string
}
