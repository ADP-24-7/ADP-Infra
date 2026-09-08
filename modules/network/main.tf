resource "ncloud_vpc" "this" {
  name            = "${var.name_prefix}-vpc"
  ipv4_cidr_block = var.vpc_cidr

  lifecycle {
    prevent_destroy = true
  }
}

resource "ncloud_subnet" "private_runtime" {
  name           = "${var.name_prefix}-private-kr1"
  vpc_no         = ncloud_vpc.this.id
  subnet         = var.private_subnet_cidr
  zone           = var.zone
  network_acl_no = ncloud_vpc.this.default_network_acl_no
  subnet_type    = "PRIVATE"
  usage_type     = "GEN"

  lifecycle {
    prevent_destroy = true
  }
}

resource "ncloud_access_control_group" "runtime" {
  name   = "${var.name_prefix}-runtime-acg"
  vpc_no = ncloud_vpc.this.id

  lifecycle {
    prevent_destroy = true
  }
}

# No ACG rule resource is intentional. Until a runtime or DB target exists,
# the QA runtime ACG remains empty and therefore default-deny.

