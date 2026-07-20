output "access_key" {
  description = "The access key for our starting user, pentest."
  value       = aws_iam_access_key.pentest.id
}

output "secret_key" {
  description = "The secret key for our starting user, pentest."
  value       = nonsensitive(aws_iam_access_key.pentest.secret)
  sensitive   = false
}


