# Audit log storage
resource "aws_s3_bucket" "audit_logs" {
  bucket = "${var.project_name}-audit-logs-${data.aws_caller_identity.current.account_id}"

  force_destroy = false

  tags = {
    Name     = "${var.project_name}-audit-logs"
    DataType = "AuditLogs"
  }
}

resource "aws_s3_bucket_versioning" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Dashboard bucket
resource "aws_s3_bucket" "dashboard" {
  bucket = "${var.project_name}-dashboard-${data.aws_caller_identity.current.account_id}"

  force_destroy = true

  tags = {
    Name = "${var.project_name}-dashboard"
  }
}

# Configure for static website hosting
resource "aws_s3_bucket_website_configuration" "dashboard" {
  bucket = aws_s3_bucket.dashboard.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Disable block public access
resource "aws_s3_bucket_public_access_block" "dashboard" {
  bucket = aws_s3_bucket.dashboard.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Bucket policy for public access
data "aws_iam_policy_document" "dashboard_public" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.dashboard.arn}/*"
    ]
  }
}

# Set bucket policy
resource "aws_s3_bucket_policy" "dashboard" {
  bucket = aws_s3_bucket.dashboard.id
  policy = data.aws_iam_policy_document.dashboard_public.json
}
