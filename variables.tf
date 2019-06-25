variable "tags" {
  default = {
    "project" = "defense-in-depth"
    "client"  = "Internal"
  }
}

variable "trail_name" {
  default = "api-calls-trail"
}

variable "bucket_prefix" {
  default = "alpha"
}

variable "lambda_function_name" {
}

variable "lambda_handler" {
}

variable "lambda_runtime" {
}

variable "lambda_iam_role_name" {
}

variable "aws_account_id" {
}

variable "aws_region" {
  default = "us-east-1"
}

variable "cloudwatch_event_rule_name" {
}

variable "cloudtrail_logs" {
}

variable "log_group" {
}

variable "cloudtrail_policy" {
}

variable "cloudtrail_role" {
}

variable "topic_name" {
  type        = string
  description = "Name of the Topic"
}

variable "display_name" {
  type        = string
  description = "Name shown in confirmation emails"
}

variable "email_addresses" {
  type        = list(string)
  description = "Email address list"
}

variable "protocol" {
  default     = "email"
  description = "Protocol to use."
  type        = string
}

variable "stack_name" {
  type        = string
  description = "Cloudformation stack name that creates the SNS topic."
}

