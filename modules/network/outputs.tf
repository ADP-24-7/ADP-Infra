output "vpc_no" {
  description = "NCP VPC identifier."
  value       = ncloud_vpc.this.id
}

output "default_network_acl_no" {
  description = "Default NACL created with the VPC and used by the QA subnet."
  value       = ncloud_vpc.this.default_network_acl_no
}

output "private_subnet_no" {
  description = "NCP private runtime subnet identifier."
  value       = ncloud_subnet.private_runtime.id
}

output "runtime_acg_no" {
  description = "NCP runtime ACG identifier."
  value       = ncloud_access_control_group.runtime.id
}

