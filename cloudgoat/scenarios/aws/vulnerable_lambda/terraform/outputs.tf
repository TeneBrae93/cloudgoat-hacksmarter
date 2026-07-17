#IAM User Credentials
output "access_key" {
  value = aws_iam_access_key.bilbo.id
}

output "secret_key" {
  value     = nonsensitive(aws_iam_access_key.bilbo.secret)
  sensitive = false
}

#AWS Account ID
output "cloudgoat_output_aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "scenario_cg_id" {
  value = var.cgid
}

output "profile" {
  value = var.profile
}
