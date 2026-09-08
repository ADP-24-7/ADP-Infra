locals {
  name_prefix = "adp-${var.environment}"
}

module "network" {
  source = "../../modules/network"

  name_prefix         = local.name_prefix
  vpc_cidr            = var.vpc_cidr
  private_subnet_cidr = var.private_subnet_cidr
  zone                = var.zone
}

module "object_storage" {
  source = "../../modules/object-storage"

  bucket_names = [
    var.data_artifacts_bucket_name,
    var.terraform_state_bucket_name,
  ]
}

