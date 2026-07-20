data "aws_caller_identity" "aws_account_id" {}

# Vulnerable Lambda Target Role
resource "aws_iam_role" "lambda_admin_execution_role" {
  name = "cg-LambdaAdminExecutionRole-${var.cgid}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_admin_execution_admin" {
  role       = aws_iam_role.lambda_admin_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Starting User
resource "aws_iam_user" "pentest" {
  name          = "cg-pentest-${var.cgid}"
  force_destroy = true
}

resource "aws_iam_access_key" "pentest" {
  user = aws_iam_user.pentest.name
}

resource "aws_iam_user_policy_attachment" "pentest_iam_read_only" {
  user       = aws_iam_user.pentest.name
  policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
}

resource "aws_iam_user_policy" "pentest_create_access_key" {
  name = "cg-pentest-create-access-key-${var.cgid}"
  user = aws_iam_user.pentest.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "iam:CreateAccessKey"
        Resource = "arn:aws:iam::*:user/*"
      }
    ]
  })
}

# Random name generation for intermediate target user
resource "random_string" "lambda_developer_name" {
  length  = 8
  special = false
  upper   = false
  numeric = false
}

# Intermediate Target User
resource "aws_iam_user" "lambda_developer" {
  name          = "cg-${random_string.lambda_developer_name.result}-${var.cgid}"
  force_destroy = true
}

resource "aws_iam_user_policy" "lambda_developer_policy" {
  name = "cg-lambda-developer-policy-${var.cgid}"
  user = aws_iam_user.lambda_developer.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:CreateFunction",
          "lambda:InvokeFunction"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = aws_iam_role.lambda_admin_execution_role.arn
      }
    ]
  })
}

# Random name generation for decoy users
resource "random_string" "decoy_names" {
  count   = 100
  length  = 8
  special = false
  upper   = false
  numeric = false
}

# Decoy Users (Noise)
resource "aws_iam_user" "decoys" {
  count         = 100
  name          = "cg-${random_string.decoy_names[count.index].result}-${var.cgid}"
  force_destroy = true
}

resource "aws_iam_user_policy_attachment" "decoy_s3_read_only" {
  count      = 100
  user       = aws_iam_user.decoys[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_user_policy_attachment" "decoy_ec2_read_only" {
  count      = 100
  user       = aws_iam_user.decoys[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# Flag in Secrets Manager to verify Admin access
resource "aws_secretsmanager_secret" "admin_flag" {
  name                    = "cg-admin-flag-${var.cgid}"
  description             = "Administrative access verification flag"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "admin_flag_val" {
  secret_id     = aws_secretsmanager_secret.admin_flag.id
  secret_string = "HSM{44c9f2969e2b49e19c9575ec081608a9}"
}
