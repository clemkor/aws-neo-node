output "lambda_arn" {
  value = "${aws_lambda_function.blockchain_archive.arn}"
}

output "lambda_role_arn" {
  value = "${aws_iam_role.blockchain_archive_lambda_role.arn}"
}

output "lambda_policy_arn" {
  value = "${aws_iam_policy.blockchain_archive_lambda_role_policy.arn}"
}
