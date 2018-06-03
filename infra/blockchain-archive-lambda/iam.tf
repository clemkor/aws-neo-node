data "aws_iam_policy_document" "blockchain_archive_assume_role_policy_document" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type = "Service"
    }
  }
}

data "aws_iam_policy_document" "blockchain_archive_lambda_role_policy_document" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["*"]
  }

  statement {
    actions = [
      "s3:PutObject"
    ]

    resources = [
      "arn:aws:s3:::${var.blockchain_archive_bucket_name}/${var.blockchain_archive_key}"
    ]
  }
}

resource "aws_iam_role" "blockchain_archive_lambda_role" {
  description = "Blockchain archive lambda role (region: ${var.region}, deployment identifier: ${var.deployment_identifier})"
  assume_role_policy = "${data.aws_iam_policy_document.blockchain_archive_assume_role_policy_document.json}"
}

resource "aws_iam_policy" "blockchain_archive_lambda_role_policy" {
  description = "Blockchain archive lambda policy (region: ${var.region}, deployment identifier: ${var.deployment_identifier})"
  policy = "${data.aws_iam_policy_document.blockchain_archive_lambda_role_policy_document.json}"
}

resource "aws_iam_role_policy_attachment" "blockchain_archive_lambda_role_policy_attachment" {
  policy_arn = "${aws_iam_policy.blockchain_archive_lambda_role_policy.arn}"
  role = "${aws_iam_role.blockchain_archive_lambda_role.name}"
}
