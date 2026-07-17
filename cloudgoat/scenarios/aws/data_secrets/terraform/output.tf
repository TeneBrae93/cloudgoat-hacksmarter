output "access_key" {
  description = "The access key for the starting user"
  value       = aws_iam_access_key.start_user.id
}

output "secret_key" {
  description = "The secret key for the starting user"
  value       = nonsensitive(aws_iam_access_key.start_user.secret)
  sensitive   = false
}