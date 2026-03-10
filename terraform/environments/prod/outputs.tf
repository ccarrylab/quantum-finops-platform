output "ml_endpoint_name" {
  description = "SageMaker ML endpoint for cost prediction"
  value       = module.ml_cost_predictor.sagemaker_endpoint_name
}

output "feature_store_bucket" {
  description = "S3 bucket for ML features"
  value       = module.ml_cost_predictor.feature_store_bucket
}

output "cost_data_bucket" {
  description = "S3 bucket for cost data"
  value       = aws_s3_bucket.cost_data.id
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.quantum_finops.dashboard_name}"
}

output "notebook_url" {
  description = "SageMaker notebook for model training"
  value       = module.ml_cost_predictor.notebook_instance_url
}

output "next_steps" {
  description = "What to do next"
  value       = <<-EOT
  
  ✅ QuantumFinOps Infrastructure Deployed!
  
  Next Steps:
  1. Open SageMaker Notebook: ${module.ml_cost_predictor.notebook_instance_url}
  2. Train ML model with your cost data
  3. Deploy model to endpoint: ${module.ml_cost_predictor.sagemaker_endpoint_name}
  4. View dashboard: https://console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.quantum_finops.dashboard_name}
  
  Cost Data Bucket: ${aws_s3_bucket.cost_data.id}
  Alerts sent to: ${var.alert_email}
  
  EOT
}
