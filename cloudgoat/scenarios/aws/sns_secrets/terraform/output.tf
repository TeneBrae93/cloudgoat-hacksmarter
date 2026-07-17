output "access_key" {
  value = aws_iam_access_key.sns_user_key.id
}

output "secret_key" {
  value     = nonsensitive(aws_iam_access_key.sns_user_key.secret)
  sensitive = false
}
