data "archive_file" "lambda_function" {
  type        = "zip"
  source_file = "assets/lambda.py"
  output_path = "assets/lambda.zip"
}

resource "aws_iam_role" "lambda_role" {
  name = "cg-lambda-role-${var.cgid}"

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

resource "aws_iam_role_policy_attachment" "lambda_role_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "log_processor" {
  function_name = "cg-log-processor-${var.cgid}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda.handler"
  runtime       = "python3.9"

  filename         = data.archive_file.lambda_function.output_path
  source_code_hash = data.archive_file.lambda_function.output_base64sha256

  environment {
    variables = {
      LAMBDA_MANAGER_AK = aws_iam_access_key.lambda_manager.id
      LAMBDA_MANAGER_SK = aws_iam_access_key.lambda_manager.secret
    }
  }
}
