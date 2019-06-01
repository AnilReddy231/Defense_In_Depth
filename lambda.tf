data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "index.py"
  output_path = "sgwatch.zip"
}

resource "aws_lambda_function" "sg_watch" {
    depends_on       = ["data.archive_file.lambda_zip"]
    filename         = "${data.archive_file.lambda_zip.output_path}"
    function_name    = "${var.lambda_function_name}"
    description      = "An Amazon Cloudwatch trigger for watching SG Ingress rules and self healing supported"
    handler          = "${var.lambda_handler}"
    runtime          = "${var.lambda_runtime}"
    source_code_hash = "${data.archive_file.lambda_zip.output_base64sha256}"
    role             = "${aws_iam_role.lambda_exec_role.arn}"
    timeout          = "30"
    memory_size      = "256"

    environment {
        variables    = {TOPIC = "${data.aws_sns_topic.sns_topic.arn}"}
    }
    tags             = "${merge(map("Name","Lambda-SG-Watch"), var.tags)}"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.lambda_iam_role_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "lambda_cloudwatch_logging" {
  name = "lambda-cloudwatch-logging"
  role = "${aws_iam_role.lambda_exec_role.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
            "ec2:DescribeSecurityGroups",
            "ec2:AuthorizeSecurityGroupIngress",
            "ec2:RevokeSecurityGroupIngress",
            "ec2:AuthorizeSecurityGroupEgress",
            "ec2:RevokeSecurityGroupEgress"
            ],
            "Resource": "*"
        },
        {
            "Effect" : "Allow",
            "Action" : [
            "sns:Publish",
            "sns:Subscribe"
            ],
            "Resource" : "*"
        }
    ]
}
EOF
}

resource "aws_lambda_permission" "cloudwatch_lambda_execution" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.sg_watch.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.sg_event.arn}"
}