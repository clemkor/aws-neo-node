module "repository" {
  source = "infrablocks/ecr-repository/aws"
  version = "0.1.10"

  repository_name = "eth-quest/${var.image_name}"
}
