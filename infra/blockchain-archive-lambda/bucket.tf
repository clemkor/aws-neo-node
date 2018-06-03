module "encrypted_bucket" {
  source = "infrablocks/encrypted-bucket/aws"
  version = "0.1.12"

  bucket_name = "${var.blockchain_archive_bucket_name}"

  providers = {
    aws = "aws"
    template = "template"
  }
}
