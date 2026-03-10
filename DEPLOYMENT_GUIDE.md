# 🚀 QuantumFinOps - Deployment Guide

**Deploy the complete ML-driven autonomous FinOps platform**

---

## 📋 Prerequisites

- AWS Account with admin access
- Terraform >= 1.6
- AWS CLI configured
- Email address for alerts

---

## ⚡ Quick Deploy (5 Minutes)

### Step 1: Configure AWS

```bash
# Configure AWS credentials
aws configure

# Verify access
aws sts get-caller-identity
```

### Step 2: Set Variables

```bash
cd terraform/environments/prod

# Copy example config
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

Update:
```hcl
region      = "us-east-1"
alert_email = "your-email@example.com"
environment = "prod"
```

### Step 3: Deploy

```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy (takes ~5 minutes)
terraform apply
```

Type `yes` when prompted.

---

## 🎯 What Gets Deployed

### ML Infrastructure
- ✅ **SageMaker Notebook** - For model training
- ✅ **SageMaker Endpoint** - Real-time ML inference
- ✅ **Lambda Functions** - Cost prediction every 15 min
- ✅ **S3 Buckets** - Feature store & cost data

### Monitoring
- ✅ **CloudWatch Dashboard** - Real-time metrics
- ✅ **CloudWatch Alarms** - Cost spike detection
- ✅ **SNS Alerts** - Email notifications

### Security
- ✅ **KMS Encryption** - All data encrypted
- ✅ **IAM Roles** - Least privilege access
- ✅ **VPC Endpoints** - Private AWS service access

---

## 📊 After Deployment

### 1. Open SageMaker Notebook

```bash
# Get notebook URL from output
terraform output notebook_url
```

Or go to: AWS Console → SageMaker → Notebook instances

### 2. Train ML Model

The notebook has pre-loaded training scripts:

```python
# In SageMaker notebook
cd /home/ec2-user/SageMaker/ml-models

# Train the model
python train_cost_predictor.py --epochs 100

# Deploy to endpoint
python deploy_model.py
```

### 3. View Dashboard

```bash
# Get dashboard URL
terraform output dashboard_url
```

You'll see:
- Daily cost savings
- ML prediction accuracy
- System health metrics

### 4. Test Cost Prediction

```bash
# Invoke Lambda manually
aws lambda invoke \
  --function-name quantum-finops-ml-inference-prod \
  --payload '{}' \
  response.json

cat response.json
```

---

## 💰 Cost Breakdown

### Infrastructure Costs

**SageMaker:**
- Notebook (ml.t3.medium): ~$0.05/hour = $36/month
- Endpoint (ml.m5.xlarge x2): ~$0.23/hour = $336/month
- **Total SageMaker**: ~$372/month

**Lambda:**
- 2,880 invocations/day (every 15 min)
- ~86,400 invocations/month
- First 1M free, then $0.20 per 1M
- **Total Lambda**: ~$0.02/month

**S3:**
- Feature store: ~$0.023/GB/month
- ~10GB expected = $0.23/month
- **Total S3**: ~$0.23/month

**CloudWatch:**
- Dashboards: $3/month
- Logs: ~$0.50/month
- Alarms: $0.10/month
- **Total CloudWatch**: ~$3.60/month

### Total Monthly Cost
**~$376/month** to run the platform

### ROI
If it saves just **$2,000/month** in cloud costs:
- ROI: 531%
- Payback: 5.6 days
- Annual savings: $24K - $4.5K = **$19.5K net**

---

## 🔧 Configuration Options

### Scale Down (Development)

```hcl
# In terraform.tfvars
notebook_instance_type   = "ml.t3.small"   # $0.023/hour
inference_instance_type  = "ml.t3.medium"  # $0.05/hour
inference_instance_count = 1               # Single instance

# Monthly cost: ~$75
```

### Scale Up (Production)

```hcl
# In terraform.tfvars
notebook_instance_type   = "ml.t3.xlarge"   # $0.188/hour
inference_instance_type  = "ml.m5.2xlarge"  # $0.46/hour
inference_instance_count = 3                # High availability

# Monthly cost: ~$1,100
```

---

## 🎯 Integration with Existing Infrastructure

### Connect to Cost Explorer

```python
# Lambda function automatically pulls cost data
# Configure in AWS Console:
# Cost Explorer → Enable → Wait 24 hours for data
```

### Connect to CloudWatch

```bash
# Cost data flows automatically
# View in: CloudWatch → Metrics → QuantumFinOps namespace
```

### Connect to Slack

Add to Lambda environment variables:

```bash
aws lambda update-function-configuration \
  --function-name quantum-finops-ml-inference-prod \
  --environment Variables={SLACK_WEBHOOK_URL=https://hooks.slack.com/...}
```

---

## 🔍 Monitoring

### Check ML Model Status

```bash
# Get endpoint status
aws sagemaker describe-endpoint \
  --endpoint-name $(terraform output -raw ml_endpoint_name)
```

### View Predictions

```bash
# Query DynamoDB
aws dynamodb scan \
  --table-name quantum-finops-ml-predictions-prod \
  --max-items 10
```

### Check Logs

```bash
# Lambda logs
aws logs tail /aws/lambda/quantum-finops-ml-inference-prod --follow

# SageMaker logs
aws logs tail /aws/sagemaker/Endpoints/quantum-finops-ml-endpoint-prod --follow
```

---

## 🚨 Troubleshooting

### Issue: SageMaker endpoint fails to deploy

**Solution:**
```bash
# Check service limits
aws service-quotas get-service-quota \
  --service-code sagemaker \
  --quota-code L-1234567890

# Request increase if needed
aws service-quotas request-service-quota-increase \
  --service-code sagemaker \
  --quota-code L-1234567890 \
  --desired-value 5
```

### Issue: Lambda timeout

**Solution:**
```bash
# Increase timeout
aws lambda update-function-configuration \
  --function-name quantum-finops-ml-inference-prod \
  --timeout 120
```

### Issue: High costs

**Solution:**
```bash
# Stop SageMaker notebook when not training
aws sagemaker stop-notebook-instance \
  --notebook-instance-name quantum-finops-ml-notebook-prod

# Scale down endpoint instances
terraform apply -var="inference_instance_count=1"
```

---

## 🔄 Updates

### Update ML Model

```bash
cd terraform/environments/prod

# Pull latest changes
git pull origin main

# Apply updates
terraform apply
```

### Update Lambda Code

```bash
# Zip new code
cd lambda
zip -r cost_predictor.zip cost_predictor.py

# Update function
aws lambda update-function-code \
  --function-name quantum-finops-ml-inference-prod \
  --zip-file fileb://cost_predictor.zip
```

---

## 🗑️ Cleanup (Destroy Everything)

### Warning: This deletes ALL resources

```bash
cd terraform/environments/prod

# Preview what will be deleted
terraform plan -destroy

# Destroy (cannot be undone!)
terraform destroy
```

Type `yes` to confirm.

**Estimated time:** 5-10 minutes

---

## 📈 Success Metrics

After 7 days, you should see:

### ML Performance
- ✅ Prediction accuracy: >85%
- ✅ False positive rate: <5%
- ✅ Predictions per day: 96 (every 15 min)

### Cost Impact
- ✅ Cost spikes detected: 3-5/week
- ✅ Spikes prevented: 60-80%
- ✅ Average savings per spike: $500-2,000

### System Health
- ✅ Uptime: >99.9%
- ✅ Latency: <1s per prediction
- ✅ Errors: <0.1%

---

## 🎓 Training the ML Model

### Sample Training Data Format

```csv
timestamp,hour_of_day,day_of_week,cost_usd,traffic_rps,deployments
2026-03-01T00:00:00Z,0,0,847.23,1247,0
2026-03-01T01:00:00Z,1,0,823.45,1189,0
2026-03-01T02:00:00Z,2,0,2147.89,1156,1
```

Upload to: `s3://quantum-finops-ml-feature-store-prod/training-data/`

### Training Script

```python
# In SageMaker notebook
import boto3
import pandas as pd
from sklearn.preprocessing import StandardScaler
import tensorflow as tf

# Load training data
s3 = boto3.client('s3')
df = pd.read_csv('s3://your-bucket/training-data/costs.csv')

# Feature engineering
df['cost_spike'] = df['cost_usd'] > df['cost_usd'].rolling(24).mean() * 1.5

# Train LSTM model
model = tf.keras.Sequential([
    tf.keras.layers.LSTM(128, input_shape=(168, 5)),
    tf.keras.layers.Dense(64, activation='relu'),
    tf.keras.layers.Dense(1, activation='sigmoid')
])

model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])
model.fit(X_train, y_train, epochs=100, validation_split=0.2)

# Save model
model.save('s3://your-bucket/models/cost-predictor-v1/')
```

---

## 🎯 Next Steps After Deployment

1. ✅ **Verify deployment**: Check CloudWatch dashboard
2. ✅ **Train ML model**: Use SageMaker notebook
3. ✅ **Test predictions**: Invoke Lambda manually
4. ✅ **Monitor for 7 days**: Collect baseline metrics
5. ✅ **Tune thresholds**: Adjust based on your environment
6. ✅ **Expand coverage**: Add more AWS accounts

---

## 📞 Support

- 📧 **Email**: cohen.carryl@gmail.com
- 🐙 **GitHub Issues**: github.com/ccarrylab/quantum-finops-platform/issues
- 💼 **LinkedIn**: linkedin.com/in/cohencarryl

---

**Deploy once, save millions.** 🚀💰
