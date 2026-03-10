import json
import boto3
import os
import hashlib
import time
from datetime import datetime
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')

# Get table names from environment variables
AUDIT_TABLE = os.environ.get('AUDIT_TABLE', 'guardrail-ai-audit-events-prod')
AUDIT_BUCKET = os.environ.get('AUDIT_BUCKET', 'guardrail-ai-audit-logs-089719647189')
POLICIES_TABLE = os.environ.get('POLICIES_TABLE', 'guardrail-ai-policies-prod')

class GuardRailPolicyEnforcer:
    def __init__(self):
        self.policies_table = dynamodb.Table(POLICIES_TABLE)
        self.audit_table = dynamodb.Table(AUDIT_TABLE)
        
    def check_pii(self, text):
        """Enhanced PII detection"""
        text_lower = text.lower()
        pii_indicators = {
            'ssn': ['ssn', 'social security', '123-45', '6789'],
            'credit_card': ['credit card', '4111', '5555', 'amex', 'visa'],
            'passport': ['passport', 'travel document'],
            'driver_license': ['driver license', 'driver\'s license', 'dl'],
            'phone': ['phone number', 'cell number', 'mobile'],
            'email': ['email address', 'e-mail']
        }
        
        detected = []
        for category, indicators in pii_indicators.items():
            for indicator in indicators:
                if indicator in text_lower:
                    detected.append(category)
                    break
        
        return len(detected) > 0, list(set(detected))  # Remove duplicates
    
    def create_audit_record(self, user_id, prompt, response, violations, approved):
        """Create audit record in DynamoDB"""
        # Generate unique event ID
        event_id = hashlib.sha256(
            f"{user_id}{datetime.utcnow().isoformat()}{prompt[:50]}".encode()
        ).hexdigest()[:16]
        
        # Calculate risk score based on violations
        risk_score = 0
        if violations:
            for v in violations:
                if v.get('severity') == 'HIGH':
                    risk_score += 25
                elif v.get('severity') == 'MEDIUM':
                    risk_score += 10
                else:
                    risk_score += 5
        
        # TTL for auto-deletion (7 years)
        ttl = int(time.time()) + (2557 * 24 * 60 * 60)
        
        item = {
            'event_id': event_id,
            'timestamp': datetime.utcnow().isoformat(),
            'user_id': user_id,
            'prompt': prompt[:500],  # Truncate for DynamoDB
            'response': response[:500],
            'violations': json.dumps(violations),
            'approved': approved,
            'risk_score': Decimal(str(min(risk_score, 100))),
            'risk_level': self.get_risk_level(risk_score),
            'ttl': int(ttl)
        }
        
        try:
            self.audit_table.put_item(Item=item)
            print(f"✅ Audit record created in DynamoDB: {event_id}")
        except Exception as e:
            print(f"❌ Failed to write to DynamoDB: {e}")
        
        return event_id
    
    def get_risk_level(self, score):
        """Convert score to risk level"""
        if score >= 75:
            return 'CRITICAL'
        elif score >= 50:
            return 'HIGH'
        elif score >= 25:
            return 'MEDIUM'
        else:
            return 'LOW'
    
    def store_in_s3(self, audit_id, full_data):
        """Store full interaction in S3 for compliance"""
        key = f"interactions/{datetime.utcnow().strftime('%Y/%m/%d')}/{audit_id}.json"
        
        try:
            s3.put_object(
                Bucket=AUDIT_BUCKET,
                Key=key,
                Body=json.dumps(full_data, indent=2),
                ContentType='application/json',
                ServerSideEncryption='AES256'
            )
            print(f"✅ Stored in S3: {key}")
            return key
        except Exception as e:
            print(f"❌ Failed to write to S3: {e}")
            return None
    
    def lambda_handler(self, event, context):
        print(f"📥 Received event: {json.dumps(event)}")
        
        # Extract data from event
        user_id = event.get('user_id', 'unknown')
        prompt = event.get('prompt', '')
        response = event.get('response', '')
        
        # Check for violations (check both prompt and response)
        full_text = f"{prompt} {response}"
        has_pii, pii_types = self.check_pii(full_text)
        
        violations = []
        if has_pii:
            violations.append({
                'type': 'PII_DETECTION',
                'severity': 'HIGH',
                'details': f'PII detected: {", ".join(pii_types)}',
                'timestamp': datetime.utcnow().isoformat()
            })
        
        approved = len(violations) == 0
        
        # Create audit record in DynamoDB
        audit_id = self.create_audit_record(
            user_id, prompt, response, violations, approved
        )
        
        # Store full interaction in S3
        s3_key = self.store_in_s3(audit_id, {
            'audit_id': audit_id,
            'user_id': user_id,
            'prompt': prompt,
            'response': response,
            'violations': violations,
            'approved': approved,
            'timestamp': datetime.utcnow().isoformat(),
            'environment': os.environ.get('ENVIRONMENT', 'prod')
        })
        
        # Return result with audit info
        result = {
            'approved': approved,
            'violations': violations,
            'user_id': user_id,
            'audit_id': audit_id,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        if s3_key:
            result['audit_location'] = f"s3://{AUDIT_BUCKET}/{s3_key}"
        
        print(f"📤 Returning: {json.dumps(result)}")
        
        return {
            'statusCode': 200,
            'body': json.dumps(result)
        }

def handler(event, context):
    enforcer = GuardRailPolicyEnforcer()
    return enforcer.lambda_handler(event, context)
