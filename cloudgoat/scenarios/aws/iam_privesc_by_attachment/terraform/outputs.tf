output "access_key" {
  description = "AWS access key id for Kerrigan"
  value       = aws_iam_access_key.kerrigan.id
}

output "secret_key" {
  description = "AWS secret access key for Kerrigan"
  value       = nonsensitive(aws_iam_access_key.kerrigan.secret)
  sensitive   = false
}

output "cloudgoat_output_aws_account_id" {
  description = "AWS account id"
  value       = data.aws_caller_identity.aws_account_id.account_id
}
