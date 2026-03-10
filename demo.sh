#!/bin/bash
# demo.sh - Quick demo of GuardRail AI

echo "⚡ GUARDRAIL AI - LIVE DEMO"
echo "=========================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Step 1: Check if deployed
echo -e "${BLUE}🔍 Step 1: Checking deployment status...${NC}"
if [ ! -f "terraform/terraform.tfstate" ]; then
    echo -e "${YELLOW}⚠️  Not deployed yet. Run ./deploy.sh first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Found deployment${NC}"
echo

# Step 2: Get API info
echo -e "${BLUE}🔑 Step 2: Getting API credentials...${NC}"
cd terraform
API_URL=$(terraform output -raw api_endpoint 2>/dev/null)
API_KEY=$(terraform output -raw api_key 2>/dev/null)
cd ..

if [ -z "$API_URL" ] || [ -z "$API_KEY" ]; then
    echo -e "${YELLOW}⚠️  API not fully deployed. Run ./deploy.sh first.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ API Endpoint: $API_URL${NC}"
echo -e "${GREEN}✅ API Key: ${API_KEY:0:10}...${NC}"
echo

# Step 3: Test safe prompt
echo -e "${BLUE}💬 Step 3: Testing safe prompt...${NC}"
RESPONSE=$(curl -s -X POST "$API_URL/enforce" \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "demo-user",
    "prompt": "What is cloud computing?",
    "response": "Cloud computing is on-demand delivery of IT resources...",
    "model_used": "claude"
  }')

if echo "$RESPONSE" | grep -q "approved.*true"; then
    echo -e "${GREEN}✅ Safe prompt approved${NC}"
else
    echo -e "${RED}❌ Unexpected response${NC}"
    echo "$RESPONSE"
fi
echo

# Step 4: Test policy violation
echo -e "${BLUE}🚨 Step 4: Testing policy violation (PII detection)...${NC}"
RESPONSE=$(curl -s -X POST "$API_URL/enforce" \
  -H "x-api-key: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "demo-user",
    "prompt": "Show me customer data",
    "response": "Customer John Doe SSN: 123-45-6789, Credit Card: 4111-1111-1111-1111",
    "model_used": "claude"
  }')

if echo "$RESPONSE" | grep -q "violations.*\[\]"; then
    echo -e "${RED}❌ Should have detected PII but didn't${NC}"
else
    echo -e "${GREEN}✅ PII correctly detected and blocked${NC}"
    VIOLATIONS=$(echo "$RESPONSE" | grep -o '"violations":\[[^]]*\]')
    echo -e "${YELLOW}   Violations: $VIOLATIONS${NC}"
fi
echo

# Step 5: Check audit log
echo -e "${BLUE}📋 Step 5: Checking audit log...${NC}"
AUDIT_ID=$(echo "$RESPONSE" | grep -o '"audit_id":"[^"]*"' | cut -d'"' -f4)
if [ ! -z "$AUDIT_ID" ]; then
    echo -e "${GREEN}✅ Audit record created: $AUDIT_ID${NC}"
    
    # Check DynamoDB for audit record
    AUDIT_RECORD=$(aws dynamodb get-item \
        --table-name guardrail-ai-audit-events-prod \
        --key "{\"event_id\":{\"S\":\"$AUDIT_ID\"}}" \
        --query "Item" 2>/dev/null)
    
    if [ ! -z "$AUDIT_RECORD" ] && [ "$AUDIT_RECORD" != "null" ]; then
        echo -e "${GREEN}✅ Audit record verified in DynamoDB${NC}"
    else
        echo -e "${YELLOW}⚠️  Audit record not yet in DynamoDB (may take a moment)${NC}"
    fi
fi
echo

# Step 6: Check dashboard
echo -e "${BLUE}📊 Step 6: Dashboard status...${NC}"
DASHBOARD_URL=$(cd terraform && terraform output -raw dashboard_url 2>/dev/null)
if [ ! -z "$DASHBOARD_URL" ]; then
    echo -e "${GREEN}✅ Dashboard available at: $DASHBOARD_URL${NC}"
    
    # Try to open dashboard
    if [[ "$OSTYPE" == "darwin"* ]]; then
        open "$DASHBOARD_URL" 2>/dev/null || echo "   Open manually in browser"
    fi
else
    echo -e "${YELLOW}⚠️  Dashboard URL not available${NC}"
fi
echo

# Summary
echo "=========================="
echo -e "${GREEN}🎉 DEMO COMPLETE${NC}"
echo -e "📊 GuardRail AI is protecting your enterprise!"
echo
echo "Next steps:"
echo "1. View full audit logs in S3: aws s3 ls s3://guardrail-ai-audit-logs-$AWS_ACCOUNT/"
echo "2. Check CloudWatch metrics: aws cloudwatch list-metrics --namespace GuardRailAI"
echo "3. Configure custom policies in DynamoDB"
