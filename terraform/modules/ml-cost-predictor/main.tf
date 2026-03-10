# ML Cost Predictor Module
# TensorFlow-based cost anomaly prediction with 4-hour lookahead
# INDUSTRY FIRST: Predictive cost optimization

terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  name_prefix = "quantum-finops-ml"
  
  common_tags = merge(
    var.tags,
    {
      Module    = "ml-cost-predictor"
      Innovation = "industry-first-ml-cost-prediction"
      Patent    = "pending"
    }
  )
}

# S3 Bucket for ML Feature Store
resource "aws_s3_bucket" "feature_store" {
  bucket = "${local.name_prefix}-feature-store-${var.environment}"

  tags = merge(
    local.common_tags,
    {
      Purpose = "cost-prediction-features"
    }
  )
}

resource "aws_s3_bucket_versioning" "feature_store" {
  bucket = aws_s3_bucket.feature_store.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "feature_store" {
  bucket = aws_s3_bucket.feature_store.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.ml.arn
    }
  }
}

# KMS Key for ML data encryption
resource "aws_kms_key" "ml" {
  description             = "KMS key for QuantumFinOps ML data"
  deletion_window_in_days = 30
  enable_key_rotation     = true

  tags = local.common_tags
}

resource "aws_kms_alias" "ml" {
  name          = "alias/${local.name_prefix}-${var.environment}"
  target_key_id = aws_kms_key.ml.key_id
}

# SageMaker IAM Role
resource "aws_iam_role" "sagemaker" {
  name = "${local.name_prefix}-sagemaker-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "sagemaker.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "sagemaker_full_access" {
  role       = aws_iam_role.sagemaker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}

resource "aws_iam_role_policy" "sagemaker_s3_access" {
  name = "s3-access"
  role = aws_iam_role.sagemaker.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.feature_store.arn,
          "${aws_s3_bucket.feature_store.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.ml.arn
      }
    ]
  })
}

# SageMaker Notebook Instance for Model Development
resource "aws_sagemaker_notebook_instance" "cost_predictor" {
  name                    = "${local.name_prefix}-notebook-${var.environment}"
  role_arn                = aws_iam_role.sagemaker.arn
  instance_type           = var.notebook_instance_type
  kms_key_id              = aws_kms_key.ml.id
  lifecycle_config_name   = aws_sagemaker_notebook_instance_lifecycle_configuration.config.name

  tags = merge(
    local.common_tags,
    {
      Purpose = "cost-prediction-model-development"
    }
  )
}

resource "aws_sagemaker_notebook_instance_lifecycle_configuration" "config" {
  name = "${local.name_prefix}-lifecycle-${var.environment}"

  on_start = base64encode(<<-EOF
    #!/bin/bash
    set -e
    
    # Install TensorFlow and dependencies
    sudo -u ec2-user -i <<'USEREOF'
    source /home/ec2-user/anaconda3/bin/activate tensorflow2_p310
    
    pip install --upgrade pip
    pip install tensorflow==2.14.0
    pip install pandas==2.1.0
    pip install scikit-learn==1.3.0
    pip install boto3==1.28.0
    pip install sagemaker==2.188.0
    
    # Clone training scripts
    cd /home/ec2-user/SageMaker
    git clone https://github.com/quantum-finops/ml-models.git || true
    
    # Download sample training data
    aws s3 sync s3://${aws_s3_bucket.feature_store.id}/training-data/ ./training-data/
    
    echo "✅ QuantumFinOps ML environment ready!"
    USEREOF
  EOF
  )
}

# Lambda function for real-time inference
resource "aws_lambda_function" "cost_predictor_inference" {
  filename         = "${path.module}/lambda/cost_predictor.zip"
  function_name    = "${local.name_prefix}-inference-${var.environment}"
  role             = aws_iam_role.lambda_inference.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/cost_predictor.zip")
  runtime          = "python3.11"
  timeout          = 60
  memory_size      = 3008  # Max memory for ML inference

  environment {
    variables = {
      FEATURE_STORE_BUCKET = aws_s3_bucket.feature_store.id
      MODEL_ENDPOINT       = aws_sagemaker_endpoint.cost_predictor.name
      PREDICTION_HORIZON   = "4"  # 4 hours ahead
      CONFIDENCE_THRESHOLD = "0.85"
    }
  }

  tags = merge(
    local.common_tags,
    {
      Purpose = "real-time-cost-prediction"
    }
  )
}

resource "aws_iam_role" "lambda_inference" {
  name = "${local.name_prefix}-lambda-inference-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_inference.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_sagemaker_invoke" {
  name = "sagemaker-invoke"
  role = aws_iam_role.lambda_inference.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sagemaker:InvokeEndpoint"
        ]
        Resource = aws_sagemaker_endpoint.cost_predictor.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.feature_store.arn,
          "${aws_s3_bucket.feature_store.arn}/*"
        ]
      }
    ]
  })
}

# EventBridge Rule - Trigger prediction every 15 minutes
resource "aws_cloudwatch_event_rule" "prediction_schedule" {
  name                = "${local.name_prefix}-prediction-schedule-${var.environment}"
  description         = "Trigger cost prediction every 15 minutes"
  schedule_expression = "rate(15 minutes)"

  tags = local.common_tags
}

resource "aws_cloudwatch_event_target" "prediction_lambda" {
  rule      = aws_cloudwatch_event_rule.prediction_schedule.name
  target_id = "CostPredictionLambda"
  arn       = aws_lambda_function.cost_predictor_inference.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_predictor_inference.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.prediction_schedule.arn
}

# SageMaker Model
resource "aws_sagemaker_model" "cost_predictor" {
  name               = "${local.name_prefix}-model-${var.environment}"
  execution_role_arn = aws_iam_role.sagemaker.arn

  primary_container {
    image          = "${var.account_id}.dkr.ecr.${var.region}.amazonaws.com/cost-predictor:latest"
    model_data_url = "s3://${aws_s3_bucket.feature_store.id}/models/cost-predictor-v1/model.tar.gz"
    
    environment = {
      MODEL_TYPE          = "LSTM"
      PREDICTION_HORIZON  = "4"
      FEATURE_WINDOW      = "168"  # 7 days of hourly data
    }
  }

  tags = local.common_tags
}

# SageMaker Endpoint Configuration
resource "aws_sagemaker_endpoint_configuration" "cost_predictor" {
  name = "${local.name_prefix}-endpoint-config-${var.environment}"

  production_variants {
    variant_name           = "primary"
    model_name             = aws_sagemaker_model.cost_predictor.name
    initial_instance_count = var.inference_instance_count
    instance_type          = var.inference_instance_type
  }

  tags = local.common_tags
}

# SageMaker Endpoint
resource "aws_sagemaker_endpoint" "cost_predictor" {
  name                 = "${local.name_prefix}-endpoint-${var.environment}"
  endpoint_config_name = aws_sagemaker_endpoint_configuration.cost_predictor.name

  tags = merge(
    local.common_tags,
    {
      CriticalService = "true"
      SLA             = "99.9%"
    }
  )
}

# DynamoDB Table for Prediction History
resource "aws_dynamodb_table" "predictions" {
  name           = "${local.name_prefix}-predictions-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "timestamp"
  range_key      = "prediction_id"

  attribute {
    name = "timestamp"
    type = "S"
  }

  attribute {
    name = "prediction_id"
    type = "S"
  }

  ttl {
    attribute_name = "expiration_time"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.ml.arn
  }

  tags = merge(
    local.common_tags,
    {
      Purpose = "prediction-audit-trail"
    }
  )
}

# CloudWatch Dashboard for ML Metrics
resource "aws_cloudwatch_dashboard" "ml_metrics" {
  dashboard_name = "${local.name_prefix}-metrics-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/SageMaker", "ModelLatency", { stat = "Average", period = 300 }],
            [".", ".", { stat = "p99", period = 300 }]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "ML Inference Latency"
          yAxis = {
            left = {
              label = "Milliseconds"
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
          title  = "Model Performance"
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
            ["QuantumFinOps", "CostSpikePrevented", { stat = "Sum", period = 86400 }],
            [".", "MoneySaved", { stat = "Sum", period = 86400 }]
          ]
          period = 86400
          stat   = "Sum"
          region = var.region
          title  = "Cost Savings Impact"
        }
      }
    ]
  })
}

# SNS Topic for Prediction Alerts
resource "aws_sns_topic" "predictions" {
  name              = "${local.name_prefix}-alerts-${var.environment}"
  kms_master_key_id = aws_kms_key.ml.id

  tags = local.common_tags
}

resource "aws_sns_topic_subscription" "predictions_email" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.predictions.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# CloudWatch Alarm - High False Positive Rate
resource "aws_cloudwatch_metric_alarm" "false_positive_rate" {
  alarm_name          = "${local.name_prefix}-high-false-positive-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FalsePositiveRate"
  namespace           = "QuantumFinOps"
  period              = 3600
  statistic           = "Average"
  threshold           = 5.0  # 5% threshold
  alarm_description   = "ML model false positive rate too high - needs retraining"
  alarm_actions       = [aws_sns_topic.predictions.arn]

  tags = local.common_tags
}

# CloudWatch Alarm - Low Prediction Accuracy
resource "aws_cloudwatch_metric_alarm" "prediction_accuracy" {
  alarm_name          = "${local.name_prefix}-low-accuracy-${var.environment}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 3
  metric_name         = "PredictionAccuracy"
  namespace           = "QuantumFinOps"
  period              = 3600
  statistic           = "Average"
  threshold           = 90.0  # 90% threshold
  alarm_description   = "ML model accuracy degraded - retraining recommended"
  alarm_actions       = [aws_sns_topic.predictions.arn]

  tags = local.common_tags
}
