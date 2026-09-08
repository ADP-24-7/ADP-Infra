variable "bucket_names" {
  description = "Private NCP Object Storage buckets managed by this module."
  type        = set(string)

  validation {
    condition     = length(var.bucket_names) > 0
    error_message = "At least one bucket name must be provided."
  }
}

