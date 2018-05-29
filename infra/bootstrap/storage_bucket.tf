module "storage_bucket" {
  source = "infrablocks/encrypted-bucket/aws"
  version = "0.1.12"

  bucket_name = "${var.storage_bucket_name}"
}
