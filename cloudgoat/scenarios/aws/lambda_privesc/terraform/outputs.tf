output "access_key" {
  value = aws_iam_access_key.chris.id
}
output "secret_key" {
  value     = nonsensitive(aws_iam_access_key.chris.secret)
  sensitive = false
}
