resource "aws_cloudwatch_event_rule" "twice_daily_events" {
  name = "twice-daily-event-${var.region}-${var.deployment_identifier}"
  description = "A scheduled event running twice daily (region: ${var.region}, deployment identifier: ${var.deployment_identifier})"

  schedule_expression = "rate(12 hours)"

  is_enabled = false
}

resource "aws_cloudwatch_event_target" "twice_daily_blockchain_archive_target" {
  rule = "${aws_cloudwatch_event_rule.twice_daily_events.name}"
  arn = "${aws_lambda_function.blockchain_archive.arn}"
}

resource "aws_lambda_permission" "twice_daily_blockchain_archive_invocation" {
  statement_id = "twice-daily-blockchain-archive-invocation"

  action = "lambda:InvokeFunction"
  principal = "events.amazonaws.com"

  source_arn = "${aws_cloudwatch_event_rule.twice_daily_events.arn}"
  function_name = "${aws_lambda_function.blockchain_archive.function_name}"
}
