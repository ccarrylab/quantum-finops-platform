output "dashboard_url" {
  description = "GuardRail dashboard URL"
  value       = aws_s3_bucket_website_configuration.dashboard.website_endpoint != null ? "http://${aws_s3_bucket_website_configuration.dashboard.website_endpoint}" : "pending"
}

output "audit_bucket" {
  description = "Audit log bucket name"
  value       = aws_s3_bucket.audit_logs.bucket
}

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = "pending"
}

output "api_key" {
  description = "API key value"
  value       = "pending"
  sensitive   = true
}
