# -----------------------------------------------------------
# setup permissions to allow cloudtrail to write to cloudwatch
# -----------------------------------------------------------
resource "aws_iam_role" "cloudtrail_role" {
  name = "${var.cloudtrail_role}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudtrail_policy" {
  name = "${var.cloudtrail_policy}"
  role = "${aws_iam_role.cloudtrail_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailCreateLogStream",
      "Effect": "Allow",
      "Action": ["logs:CreateLogStream"],
      "Resource": [
        "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail.id}:log-stream:*"
      ]
    },
    {
      "Sid": "AWSCloudTrailPutLogEvents",
      "Effect": "Allow",
      "Action": ["logs:PutLogEvents"],
      "Resource": [
        "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:${aws_cloudwatch_log_group.cloudtrail.id}:log-stream:*"
      ]
    }
  ]
}
EOF
}

# -----------------------------------------------------------
# setup cloudwatch logs to receive cloudtrail events
# -----------------------------------------------------------

resource "aws_cloudwatch_log_group" "cloudtrail" {
  name = "${var.log_group}"

  retention_in_days = 30
  tags              = "${merge(map("Name","Cloudtrail"), var.tags)}"
}

# -----------------------------------------------------------
# turn cloudtrail on for all regions
# -----------------------------------------------------------

resource "aws_cloudtrail" "api_calls" {
  name                          = "${var.trail_name}"
  s3_bucket_name                = "${aws_s3_bucket.log_bucket.id}"
  s3_key_prefix                 = "${var.bucket_prefix}"
  include_global_service_events = true
  enable_logging                = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}"
  cloud_watch_logs_role_arn     = "${aws_iam_role.cloudtrail_role.arn}"
  
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  tags = "${merge(map("Name","account audit"), var.tags)}"
}

resource "aws_s3_bucket" "log_bucket" {
  bucket        = "${var.cloudtrail_logs}"
  force_destroy = true
   policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::${var.cloudtrail_logs}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${var.cloudtrail_logs}/*",
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}