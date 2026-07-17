output "access_key" {
  description = "The access key for our starting user."
  value       = aws_iam_access_key.low_priv_key.id
}

output "secret_key" {
  description = "The secret key for our starting user."
  value       = nonsensitive(aws_iam_access_key.low_priv_key.secret)
  sensitive   = false
}