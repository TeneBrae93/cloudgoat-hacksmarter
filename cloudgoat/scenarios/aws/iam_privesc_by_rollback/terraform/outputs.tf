output "access_key" {
  description = "The access key ID for the Raynor user"
  value       = aws_iam_access_key.raynor.id
}

output "secret_key" {
  description = "The secret access key for the Raynor user"
  value       = nonsensitive(aws_iam_access_key.raynor.secret)
  sensitive   = false
}
