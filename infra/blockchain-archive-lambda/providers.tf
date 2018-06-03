provider "aws" {
  region = "${var.region}"
  version = "~> 1.9"
}

provider "archive" {
  version = "~> 1.0"
}

provider "template" {
  version = "~> 1.0"
}
