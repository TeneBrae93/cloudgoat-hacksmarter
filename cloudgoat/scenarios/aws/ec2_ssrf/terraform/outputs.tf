output "access_key" {
  value = aws_iam_access_key.solus.id
}

output "secret_key" {
  value     = nonsensitive(aws_iam_access_key.solus.secret)
  sensitive = false
}
