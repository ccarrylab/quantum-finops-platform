#!/bin/bash

echo "📦 Preparing to push deployment files to GitHub..."

# Add new files
git add terraform/environments/
git add DEPLOYMENT_GUIDE.md
git add SETUP_GUIDE.md

# Commit
git commit -m "Add complete deployment infrastructure

- Production Terraform environment with ML cost predictor
- Development environment configuration
- Comprehensive deployment guide with cost breakdown
- Setup guide for GitHub and job applications
- Deployable in 5 minutes with terraform apply

Infrastructure includes:
- SageMaker notebook and endpoint
- Lambda cost prediction (every 15 min)
- CloudWatch dashboards and alarms
- S3 buckets for features and cost data
- SNS alerts for cost spikes
- Full IAM and KMS security

Monthly cost: ~$376 (ROI: 531% at $2K savings/month)"

# Push to GitHub
git push origin main

echo "✅ Updates pushed to https://github.com/ccarrylab/quantum-finops-platform"
