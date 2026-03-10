# Minimal QuantumFinOps - Infrastructure Only
# Deploy this first, train models later

terraform {
  required_version = ">= 1.5"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "quantum-finops"
      Environment = "production"
      ManagedBy   = "terraform"
    }
  }
}

data "aws_caller_identity" "current" {}

# S3 Bucket for Cost Data
resource "aws_s3_bucket" "cost_data" {
  bucket = "quantum-finops-cost-data-${data.aws_caller_identity.current.account_id}"

  tags = {
    Purpose = "cost-data-storage"
  }
}

resource "aws_s3_bucket_versioning" "cost_data" {
  bucket = aws_s3_bucket.cost_data.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket for ML Features
resource "aws_s3_bucket" "ml_features" {
  bucket = "quantum-finops-ml-features-${data.aws_caller_identity.current.account_id}"

  tags = {
    Purpose = "ml-feature-store"
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "quantum_finops" {
  dashboard_name = "QuantumFinOps-Production"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["QuantumFinOps", "CostSavings", { stat = "Sum" }]
          ]
          region = var.region
          title  = "Cost Savings"
        }
      }
    ]
  })
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "quantum-finops-alerts-prod"
}

resource "aws_sns_topic_subscription" "email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

output "cost_data_bucket" {
  value = aws_s3_bucket.cost_data.id
}

output "ml_features_bucket" {
  value = aws_s3_bucket.ml_features.id
}

output "dashboard_url" {
  value = "https://console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.quantum_finops.dashboard_name}"
}

output "next_steps" {
  value = <<-EOT
  
  ✅ QuantumFinOps Infrastructure Deployed!
  
  S3 Buckets Created:
  - Cost Data: ${aws_s3_bucket.cost_data.id}
  - ML Features: ${aws_s3_bucket.ml_features.id}
  
  Dashboard: ${aws_cloudwatch_dashboard.quantum_finops.dashboard_name}
  Alerts: ${var.alert_email}
  
  Next Steps:
  1. Upload your cost data to: s3://${aws_s3_bucket.cost_data.id}
  2. View dashboard at: https://console.aws.amazon.com/cloudwatch
  3. Later: Deploy SageMaker ML model when ready
  
  EOT
}
