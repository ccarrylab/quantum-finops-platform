output "sagemaker_endpoint_name" {
  description = "Name of the SageMaker endpoint"
  value       = aws_sagemaker_endpoint.cost_predictor.name
}

output "feature_store_bucket" {
  description = "S3 bucket for ML feature store"
  value       = aws_s3_bucket.feature_store.id
}

output "notebook_instance_url" {
  description = "URL of the SageMaker notebook instance"
  value       = "https://${aws_sagemaker_notebook_instance.cost_predictor.name}.notebook.${var.region}.sagemaker.aws"
}

output "prediction_lambda_arn" {
  description = "ARN of the prediction Lambda function"
  value       = aws_lambda_function.cost_predictor_inference.arn
}

output "predictions_table_name" {
  description = "DynamoDB table for prediction history"
  value       = aws_dynamodb_table.predictions.name
}

output "dashboard_url" {
  description = "CloudWatch dashboard URL"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.ml_metrics.dashboard_name}"
}
