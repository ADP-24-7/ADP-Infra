output "bucket_names" {
  description = "Bucket names keyed by their stable logical name."
  value       = { for name, bucket in ncloud_objectstorage_bucket.this : name => bucket.bucket_name }
}
