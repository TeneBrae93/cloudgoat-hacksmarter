# Starting User: pentest
resource "aws_iam_user" "pentest" {
  name          = "cg-pentest-${var.cgid}"
  force_destroy = true
}

resource "aws_iam_access_key" "pentest" {
  user = aws_iam_user.pentest.name
}

resource "aws_iam_policy" "pentest" {
  name = "cg-pentest-policy-${var.cgid}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:ListFunctions",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "pentest" {
  user       = aws_iam_user.pentest.name
  policy_arn = aws_iam_policy.pentest.arn
}


# Intermediate User: lambda-manager
resource "aws_iam_user" "lambda_manager" {
  name          = "cg-lambda-manager-${var.cgid}"
  force_destroy = true
}

resource "aws_iam_access_key" "lambda_manager" {
  user = aws_iam_user.lambda_manager.name
}

resource "aws_iam_policy" "lambda_manager" {
  name = "cg-lambda-manager-policy-${var.cgid}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = [
          aws_s3_bucket.engineering_scripts.arn,
          "${aws_s3_bucket.engineering_scripts.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "lambda_manager" {
  user       = aws_iam_user.lambda_manager.name
  policy_arn = aws_iam_policy.lambda_manager.arn
}


# Intermediate User: wp-manager
resource "aws_iam_user" "wp_manager" {
  name          = "cg-wp-manager-${var.cgid}"
  force_destroy = true
}

resource "aws_iam_access_key" "wp_manager" {
  user = aws_iam_user.wp_manager.name
}

resource "aws_iam_policy" "wp_manager" {
  name = "cg-wp-manager-policy-${var.cgid}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "wp_manager" {
  user       = aws_iam_user.wp_manager.name
  policy_arn = aws_iam_policy.wp_manager.arn
}


# EC2 IAM Role
resource "aws_iam_role" "ec2_role" {
  name = "cg-ec2-role-${var.cgid}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Effect = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "ec2_role_policy" {
  name        = "cg-ec2-role-policy-${var.cgid}"
  description = "Permissions for the EC2 Instance Role"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:ListSecrets",
          "secretsmanager:GetSecretValue"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_role_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_role_policy.arn
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "cg-ec2-instance-profile-${var.cgid}"
  role = aws_iam_role.ec2_role.name
}
