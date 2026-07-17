#AWS Account ID
output "cloudgoat_output_aws_account_id" {
  value = data.aws_caller_identity.aws-account-id.account_id
}
output "scenario_cg_id" {
  value = var.cgid
}

#IAM User Credentials
output "access_key" {
  value = aws_iam_access_key.starting_user_key.id
}
output "secret_key" {
  value     = nonsensitive(aws_iam_access_key.starting_user_key.secret)
  sensitive = false
}