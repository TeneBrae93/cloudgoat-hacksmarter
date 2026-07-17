output "access_key" {
  description = "Manager Access Key ID"
  value       = aws_iam_access_key.manager.id
}

output "secret_key" {
  description = "Manager Secret Access Key"
  value       = nonsensitive(aws_iam_access_key.manager.secret)
  sensitive   = false

}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}
