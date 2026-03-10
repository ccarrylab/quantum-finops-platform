#!/bin/bash
# fix_terraform.sh - Fix all Terraform issues

echo "🔧 Fixing Terraform configuration..."

# Fix s3.tf
sed -i '' '/# Dashboard bucket/,/^}/c\
# Dashboard bucket\
resource "aws_s3_bucket" "dashboard" {\
  bucket = "${var.project_name}-dashboard-${data.aws_caller_identity.current.account_id}"\
  \
  force_destroy = true\
  \
  tags = {\
    Name = "${var.project_name}-dashboard"\
  }\
}\
\
# Configure for static website hosting\
resource "aws_s3_bucket_website_configuration" "dashboard" {\
  bucket = aws_s3_bucket.dashboard.id\
\
  index_document {\
    suffix = "index.html"\
  }\
\
  error_document {\
    key = "error.html"\
  }\
}\
\
# Disable block public access FIRST\
resource "aws_s3_bucket_public_access_block" "dashboard" {\
  bucket = aws_s3_bucket.dashboard.id\
\
  block_public_acls       = false\
  block_public_policy     = false\
  ignore_public_acls      = false\
  restrict_public_buckets = false\
}\
\
# Then set bucket policy\
resource "aws_s3_bucket_policy" "dashboard" {\
  depends_on = [aws_s3_bucket_public_access_block.dashboard]\
  bucket = aws_s3_bucket.dashboard.id\
  policy = data.aws_iam_policy_document.dashboard_public.json\
}\
' terraform/s3.tf

# Fix outputs.tf
sed -i '' 's|value.*=.*"http://${aws_s3_bucket.dashboard.website_endpoint}"|value       = aws_s3_bucket_website_configuration.dashboard.website_endpoint != null ? "http://${aws_s3_bucket_website_configuration.dashboard.website_endpoint}" : "pending"|' terraform/outputs.tf

echo "✅ Fixes applied!"

# Now run terraform
cd terraform
terraform fmt
terraform validate
terraform plan
