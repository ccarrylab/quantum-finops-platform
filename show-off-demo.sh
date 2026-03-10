#!/bin/bash
echo "╔════════════════════════════════════════════════════╗"
echo "║     GUARDRAIL AI - LIVE DEMO                       ║"
echo "║     Enterprise AI Governance Platform               ║"
echo "╚════════════════════════════════════════════════════╝"

# Test 1: Safe Content
echo -e "\n📝 TEST 1: Safe Business Content"
echo "----------------------------------------"
cat > safe.json << 'END'
{"user_id": "ceo@company.com", "prompt": "What's our strategy?", "response": "Focus on AI governance"}
END

aws lambda invoke \
  --function-name guardrail-ai-policy-enforcer-prod \
  --payload file://safe.json \
  --cli-binary-format raw-in-base64-out \
  response.json > /dev/null

echo "✅ Approved: $(cat response.json | python3 -m json.tool | grep approved)"
echo "📋 Audit ID: $(cat response.json | python3 -m json.tool | grep audit_id)"

# Test 2: PII Content (Should Block)
echo -e "\n🚨 TEST 2: PII Detection (Should BLOCK)"
echo "----------------------------------------"
cat > pii.json << 'END'
{"user_id": "hr@company.com", "prompt": "Employee records", "response": "SSN: 123-45-6789"}
END

aws lambda invoke \
  --function-name guardrail-ai-policy-enforcer-prod \
  --payload file://pii.json \
  --cli-binary-format raw-in-base64-out \
  response.json > /dev/null

echo "❌ Approved: $(cat response.json | python3 -m json.tool | grep approved)"
echo "🚫 Violations: $(cat response.json | python3 -m json.tool | grep -o '"details":"[^"]*"')"

# Show DynamoDB count
echo -e "\n📊 Audit Database Status:"
COUNT=$(aws dynamodb scan --table-name guardrail-ai-audit-events-prod --select COUNT --query 'Count' --output text)
echo "Total Records: $COUNT"

# Cleanup
rm -f safe.json pii.json response.json

echo -e "\n✅ Demo Complete!"
