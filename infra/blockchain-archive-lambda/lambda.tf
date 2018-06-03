data "archive_file" "blockchain_archive_lambda_contents" {
  type = "zip"
  source_dir = "${path.module}/../../lambda-definitions/blockchain-archive"
  output_path = "${path.cwd}/build/blockchain-archive.zip"
}

resource "aws_lambda_function" "blockchain_archive" {
  function_name = "blockchain-archive-lambda-${var.region}-${var.deployment_identifier}"

  filename = "${data.archive_file.blockchain_archive_lambda_contents.output_path}"
  source_code_hash = "${data.archive_file.blockchain_archive_lambda_contents.output_base64sha256}"

  handler = "blockchain_archive_lambda.refresh_blockchain_archive"

  runtime = "python3.6"
  timeout = 300
  memory_size = 512

  role = "${aws_iam_role.blockchain_archive_lambda_role.arn}"

  environment {
    variables {
      BLOCKCHAIN_ARCHIVE_URL = "${var.blockchain_archive_url}"
      BLOCKCHAIN_ARCHIVE_BUCKET_NAME = "${var.blockchain_archive_bucket_name}"
      BLOCKCHAIN_ARCHIVE_KEY = "${var.blockchain_archive_key}"
      BLOCKCHAIN_ARCHIVE_CHUNK_SIZE_BYTES = "${var.blockchain_archive_chunk_size_bytes}"
    }
  }
}
