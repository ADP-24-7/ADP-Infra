terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    ncloud = {
      source  = "NaverCloudPlatform/ncloud"
      version = "4.0.7"
    }
  }

  # Start with `terraform init -backend=false` while adopting the existing
  # state bucket, then migrate with backend.hcl.example (see bootstrap docs).
  backend "s3" {}
}

provider "ncloud" {
  region      = var.region
  site        = var.site
  support_vpc = true
}

