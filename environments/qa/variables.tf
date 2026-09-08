variable "region" {
  description = "NCP region code. Credentials are read only from NCLOUD_* environment variables."
  type        = string
  default     = "KR"
}

variable "site" {
  description = "NCP site: public, gov, or fin."
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "gov", "fin"], var.site)
    error_message = "site must be one of: public, gov, fin."
  }
}

variable "environment" {
  description = "Deployment environment used in resource naming."
  type        = string
  default     = "qa"

  validation {
    condition     = contains(["qa"], var.environment)
    error_message = "This baseline intentionally supports only the qa environment."
  }
}

variable "zone" {
  description = "NCP zone that contains the adopted private subnet."
  type        = string
  default     = "KR-1"
}

variable "vpc_cidr" {
  description = "CIDR of the adopted QA VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "private_subnet_cidr" {
  description = "CIDR of the adopted QA private subnet."
  type        = string
  default     = "10.20.10.0/24"
}

variable "data_artifacts_bucket_name" {
  description = "Bucket shared through versioned manifests and SHA-256 digests."
  type        = string
  default     = "adp-qa-data-artifacts"
}

variable "terraform_state_bucket_name" {
  description = "Bucket reserved for Terraform state."
  type        = string
  default     = "adp-qa-tfstate"
}

