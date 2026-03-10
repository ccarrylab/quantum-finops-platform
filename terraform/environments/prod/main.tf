# QuantumFinOps Production Environment
# Deploy the complete ML-driven autonomous FinOps platform

terraform {
  required_version = ">= 1.6"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state (update bucket name after first apply)
  # backend "s3" {
  #   bucket         = "quantum-finops-terraform-state"
  #   key            = "prod/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "quantum-finops-terraform-locks"
  # }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project     = "quantum-finops"
      Environment = "production"
      ManagedBy   = "terraform"
      Innovation  = "industry-first"
      Owner       = "cohen-carryl"
    }
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# ML Cost Predictor Module
module "ml_cost_predictor" {
  source = "../../modules/ml-cost-predictor"

  environment               = "prod"
  region                    = var.region
  account_id                = data.aws_caller_identity.current.account_id
  notebook_instance_type    = "ml.t3.medium"
  inference_instance_type   = "ml.m5.xlarge"
  inference_instance_count  = 2
  alert_email               = var.alert_email

  tags = {
    Component = "ml-cost-prediction"
    CostCenter = "innovation"
  }
}

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

resource "aws_s3_bucket_server_side_encryption_configuration" "cost_data" {
  bucket = aws_s3_bucket.cost_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
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
            ["QuantumFinOps", "CostSavings", { stat = "Sum", period = 86400 }],
            [".", "CostSpikePrevented", { stat = "Sum", period = 86400 }]
          ]
          period = 86400
          stat   = "Sum"
          region = var.region
          title  = "Daily Cost Savings"
          yAxis = {
            left = {
              label = "USD"
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["QuantumFinOps", "PredictionAccuracy", { stat = "Average", period = 3600 }],
            [".", "FalsePositiveRate", { stat = "Average", period = 3600 }]
          ]
          period = 3600
          stat   = "Average"
          region = var.region
          title  = "ML Model Performance"
          yAxis = {
            left = {
              label = "Percentage"
              min   = 0
              max   = 100
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/Lambda", "Invocations", { stat = "Sum", period = 300 }],
            [".", "Errors", { stat = "Sum", period = 300 }]
          ]
          period = 300
          stat   = "Sum"
          region = var.region
          title  = "System Health"
        }
      }
    ]
  })
}

# SNS Topic for Alerts
resource "aws_sns_topic" "quantum_finops_alerts" {
  name = "quantum-finops-alerts-prod"

  tags = {
    Purpose = "cost-anomaly-alerts"
  }
}

resource "aws_sns_topic_subscription" "alerts_email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.quantum_finops_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Alarm - High Cost Spike
resource "aws_cloudwatch_metric_alarm" "cost_spike" {
  alarm_name          = "quantum-finops-cost-spike-detected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "PredictedCostSpike"
  namespace           = "QuantumFinOps"
  period              = 900
  statistic           = "Maximum"
  threshold           = 50.0  # 50% spike threshold
  alarm_description   = "Cost spike predicted - auto-remediation triggered"
  alarm_actions       = [aws_sns_topic.quantum_finops_alerts.arn]

  tags = {
    Severity = "high"
  }
}
