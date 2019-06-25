# -----------------------------------------------------------
# setup audit filters
# -----------------------------------------------------------

# ----------------------
# look for changes to security groups
# ----------------------
resource "aws_cloudwatch_event_rule" "sg_event" {
  name        = var.cloudwatch_event_rule_name
  description = "Capture SG changes like new rules and SG creation"

  event_pattern = <<PATTERN
{
  "detail-type": [
    "AWS API Call via CloudTrail"
  ],
  "detail": {
    "eventSource": [
      "ec2.amazonaws.com"
    ],
    "eventName": [
      "AuthorizeSecurityGroupIngress",
      "AuthorizeSecurityGroupEgress"
    ]
  }
}
PATTERN

}

resource "aws_cloudwatch_event_target" "lamda_event" {
  rule = aws_cloudwatch_event_rule.sg_event.name
  target_id = "Invoke_SG_Lamda"
  arn = aws_lambda_function.sg_watch.arn
}

