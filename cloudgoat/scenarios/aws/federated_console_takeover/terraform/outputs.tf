## Output Configuration for federated_console_takeover scenario

# Initial access credentials
output "access_key" {
  value = aws_iam_access_key.initial_user.id
}

output "secret_key" {
  value     = nonsensitive(aws_iam_access_key.initial_user.secret)
  sensitive = false
}


# Scenario instructions
output "secret_key" {
  value     = <<EOT
  
========================[ federated_console_takeover ]========================

INITIAL ACCESS:
  AWS Access Key ID: ${aws_iam_access_key.initial_user.id}
  AWS Secret Key: ${nonsensitive(aws_iam_access_key.initial_user.secret)}
  Region: ${var.region}

SCENARIO OBJECTIVE:
  Pivot from limited AWS CLI access to AWS Management Console 
  with elevated permissions through IMDSv2 exploitation.

========================[ Good luck and happy hacking! ]========================

EOT
  sensitive = false
} 