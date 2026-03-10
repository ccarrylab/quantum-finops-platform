# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach basic Lambda policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Policy Enforcer Lambda
resource "aws_lambda_function" "policy_enforcer" {
  filename      = "../dist/policy_enforcer.zip"
  function_name = "${var.project_name}-policy-enforcer-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.12"
  timeout       = 60
  memory_size   = 256

  environment {
    variables = {
      AUDIT_BUCKET = aws_s3_bucket.audit_logs.bucket
    }
  }
}

# Auto-remediation Lambda
resource "aws_lambda_function" "auto_remediation" {
  filename      = "../dist/auto_remediation.zip"
  function_name = "${var.project_name}-auto-remediation-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.12"
  timeout       = 60
  memory_size   = 256

  environment {
    variables = {
      AUDIT_BUCKET = aws_s3_bucket.audit_logs.bucket
    }
  }
}

# Carbon scheduler Lambda
resource "aws_lambda_function" "carbon_scheduler" {
  filename      = "../dist/carbon_scheduler.zip"
  function_name = "${var.project_name}-carbon-scheduler-${var.environment}"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.12"
  timeout       = 60
  memory_size   = 256

  environment {
    variables = {
      AUDIT_BUCKET = aws_s3_bucket.audit_logs.bucket
    }
  }
}
