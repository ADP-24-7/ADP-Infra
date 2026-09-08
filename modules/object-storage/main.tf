resource "ncloud_objectstorage_bucket" "this" {
  for_each = var.bucket_names

  bucket_name = each.value

  lifecycle {
    prevent_destroy = true
  }
}

# Bucket/object ACL resources are deliberately absent. ADP buckets must remain
# private, and applications receive scoped credentials outside Terraform state.

