#!/bin/bash
# deploy.sh - One-click deployment for GuardRail AI

echo "🚀 GuardRail AI - Enterprise Governance Platform"
echo "================================================"
echo

# Check prerequisites
echo "🔍 Checking prerequisites..."
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform required but not installed. Aborting." >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI required but not installed. Aborting." >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "❌ Python3 required but not installed. Aborting." >&2; exit 1; }
echo "✅ All prerequisites met"
echo

# Configure AWS credentials
echo "🔐 Configuring AWS..."
aws sts get-caller-identity >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ AWS credentials not configured. Run 'aws configure' first."
    exit 1
fi
AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo "✅ AWS Account: $AWS_ACCOUNT"
echo

# Create Terraform backend
echo "🏗️ Creating Terraform backend..."
aws s3 mb s3://guardrail-terraform-state-$AWS_ACCOUNT 2>/dev/null || true
aws dynamodb create-table \
    --table-name terraform-state-lock \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST 2>/dev/null || true
echo "✅ Backend ready"
echo

# Package Lambda functions
echo "📦 Packaging Lambda functions..."
mkdir -p dist

# Policy Enforcer
cd lambda/policy_enforcer
pip3 install -r requirements.txt -t . 2>/dev/null
zip -r ../../dist/policy_enforcer.zip . >/dev/null
cd ../..
echo "✅ Policy Enforcer packaged"

# Deploy infrastructure
echo "🏗️ Deploying infrastructure with Terraform..."
cd terraform

# Initialize Terraform
terraform init \
    -backend-config="bucket=guardrail-terraform-state-$AWS_ACCOUNT" \
    -backend-config="key=prod/terraform.tfstate" \
    -backend-config="region=us-east-1"

# Plan deployment
echo "📋 Generating deployment plan..."
terraform plan -out=tfplan

# Ask for confirmation
echo
read -p "⚠️ Review the plan above. Deploy to production? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    # Apply
    terraform apply tfplan
    
    # Get outputs
    API_URL=$(terraform output -raw api_endpoint 2>/dev/null || echo "pending")
    DASHBOARD_URL=$(terraform output -raw dashboard_url 2>/dev/null || echo "pending")
    API_KEY=$(terraform output -raw api_key 2>/dev/null || echo "pending")
    
    echo
    echo "🎉 DEPLOYMENT COMPLETE!"
    echo "========================"
    echo "API Endpoint: $API_URL"
    echo "Dashboard: $DASHBOARD_URL"
    echo "API Key: $API_KEY"
    echo
    echo "📊 Next steps:"
    echo "1. Configure policies in DynamoDB"
    echo "2. Set up users in Cognito"
    echo "3. Integrate API with your AI tools"
    echo "4. View dashboard at $DASHBOARD_URL"
else
    echo "❌ Deployment cancelled"
    exit 0
fi
