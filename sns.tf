# -----------------------------------------------------------
# set up SNS for sending alerts out. note there is only rudimentary security on this
# -----------------------------------------------------------

data "aws_sns_topic" "sns_topic" {
  depends_on = [aws_cloudformation_stack.sns_topic]
  name       = var.topic_name
}

data "template_file" "cloudformation_sns_stack" {
  template = file("${path.module}/email-sns-stack.json.tpl")

  vars = {
    topic_name   = var.topic_name
    display_name = var.display_name
    subscriptions = join(
      ",",
      formatlist(
        "{ \"Endpoint\": \"%s\", \"Protocol\": \"%s\"  }",
        var.email_addresses,
        var.protocol,
      ),
    )
  }
}

resource "aws_cloudformation_stack" "sns_topic" {
  name          = var.stack_name
  template_body = data.template_file.cloudformation_sns_stack.rendered

  tags = merge(
    {
      "Name" = var.stack_name
    },
  )
}

