terraform {
  backend "s3" {
    bucket = "terraform-trackit"
    key    = "api-calls/"
    region = "us-west-2"
    encrypt = "true"
  }
}
