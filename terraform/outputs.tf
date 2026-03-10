output "dashboard_url" {
  description = "GuardRail dashboard URL"
  value       = "http://${aws_s3_bucket_website_configuration.dashboard.website_endpoint}"
}

output "audit_bucket" {
  description = "Audit log bucket name"
  value       = aws_s3_bucket.audit_logs.bucket
}

output "policy_enforcer_arn" {
  description = "Policy Enforcer Lambda ARN"
  value       = aws_lambda_function.policy_enforcer.arn
}

output "auto_remediation_arn" {
  description = "Auto Remediation Lambda ARN"
  value       = aws_lambda_function.auto_remediation.arn
}

output "carbon_scheduler_arn" {
  description = "Carbon Scheduler Lambda ARN"
  value       = aws_lambda_function.carbon_scheduler.arn
}

output "policies_table" {
  description = "Policies DynamoDB table name"
  value       = aws_dynamodb_table.policies.name
}

output "audit_table" {
  description = "Audit events DynamoDB table name"
  value       = aws_dynamodb_table.audit_events.name
}

output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = "pending (add API Gateway next)"
}

output "api_key" {
  description = "API key value"
  value       = "pending (add API Gateway next)"
  sensitive   = true
}
