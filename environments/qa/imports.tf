# Console bootstrap inventory adopted on 2026-09-08. These import blocks are
# idempotent: once state contains the resources, later plans do not re-import.
import {
  to = module.network.ncloud_vpc.this
  id = "147670"
}

import {
  to = module.network.ncloud_subnet.private_runtime
  id = "321923"
}

import {
  to = module.network.ncloud_access_control_group.runtime
  id = "393431"
}

import {
  to = module.object_storage.ncloud_objectstorage_bucket.this["adp-qa-data-artifacts"]
  id = "adp-qa-data-artifacts"
}

import {
  to = module.object_storage.ncloud_objectstorage_bucket.this["adp-qa-tfstate"]
  id = "adp-qa-tfstate"
}

