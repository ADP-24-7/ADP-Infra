variable "name_prefix" {
  description = "Prefix shared by NCP QA network resources."
  type        = string

  validation {
    condition     = length(trimspace(var.name_prefix)) > 0
    error_message = "name_prefix must not be empty."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR assigned to the QA VPC."
  type        = string
}

variable "private_subnet_cidr" {
  description = "IPv4 CIDR assigned to the private runtime subnet."
  type        = string
}

variable "zone" {
  description = "NCP zone for the private runtime subnet."
  type        = string
}

