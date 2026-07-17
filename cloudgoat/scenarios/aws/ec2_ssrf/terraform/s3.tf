data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "secret_bucket" {
  bucket        = "cg-secret-s3-bucket-${data.aws_caller_identity.current.account_id}"
  force_destroy = true

  tags = {
    Description = "CloudGoat ${var.cgid} S3 Bucket used for storing a secret"
  }
}

resource "aws_s3_object" "shepards_credentials" {
  bucket  = aws_s3_bucket.secret_bucket.id
  key     = "/aws/credentials"
  content = <<-CONTENT
    [default]
    aws_access_key_id = ${aws_iam_access_key.shepard.id}
    aws_secret_access_key = ${aws_iam_access_key.shepard.secret}
    region = ${var.region}
  CONTENT
}
