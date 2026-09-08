output "vpc_no" {
  description = "NCP QA VPC identifier."
  value       = module.network.vpc_no
}

output "private_subnet_no" {
  description = "NCP QA private runtime subnet identifier."
  value       = module.network.private_subnet_no
}

output "runtime_acg_no" {
  description = "NCP QA runtime ACG identifier."
  value       = module.network.runtime_acg_no
}

output "bucket_names" {
  description = "NCP QA data/artifact and Terraform state bucket names."
  value       = module.object_storage.bucket_names
}

