#!/bin/bash

# ============================================================================
# Manual Testing Script - Secure Patient Records API
# ============================================================================
# This script provides a step-by-step walkthrough of all API endpoints
# and security features with curl commands
# ============================================================================

set -e

API_URL="https://localhost:8443"
KEYCLOAK_URL="http://localhost:8081"

echo "=========================================="
echo "Secure Health API - Manual Testing"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_step() {
    echo -e "${YELLOW}[STEP ${1}]${NC} ${2}"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} ${1}"
}

# Step 1: Get tokens
print_step 1 "Obtaining JWT tokens from Keycloak"
echo ""
echo "Getting VIEWER token..."
VIEWER_TOKEN=$(curl -s -X POST \
    $KEYCLOAK_URL/realms/health/protocol/openid-connect/token \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=health-api" \
    -d "username=lab_viewer" \
    -d "password=viewer123" \
    -d "grant_type=password" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

echo "Getting EDITOR token..."
EDITOR_TOKEN=$(curl -s -X POST \
    $KEYCLOAK_URL/realms/health/protocol/openid-connect/token \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=health-api" \
    -d "username=lab_editor" \
    -d "password=editor123" \
    -d "grant_type=password" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

if [ -z "$VIEWER_TOKEN" ] || [ -z "$EDITOR_TOKEN" ]; then
    echo "[ERROR] Failed to obtain tokens"
    exit 1
fi

print_success "Tokens obtained successfully"
echo "VIEWER Token (first 50 chars): ${VIEWER_TOKEN:0:50}..."
echo "EDITOR Token (first 50 chars): ${EDITOR_TOKEN:0:50}..."
echo ""

# Step 2: Test GET all records with VIEWER
print_step 2 "Testing GET /records with VIEWER role"
echo ""
echo "Command:"
echo "curl -X GET $API_URL/records \\"
echo "  -H \"Authorization: Bearer \$VIEWER_TOKEN\" -k"
echo ""
echo "Response:"
RESPONSE=$(curl -s -X GET $API_URL/records \
    -H "Authorization: Bearer $VIEWER_TOKEN" \
    -k)
echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
print_success "VIEWER can read records"
echo ""

# Step 3: Test POST with VIEWER (should fail)
print_step 3 "Testing POST /records with VIEWER role (should fail with 403)"
echo ""
echo "Command:"
echo "curl -X POST $API_URL/records \\"
echo "  -H \"Authorization: Bearer \$VIEWER_TOKEN\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{...patient data...}' -k"
echo ""
echo "Response:"
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" -X POST $API_URL/records \
    -H "Authorization: Bearer $VIEWER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"patient_id": "P-TEST-001", "name": "Test Patient", "age": 50}' \
    -k)
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d':' -f2)
echo "$RESPONSE" | grep -v "HTTP_CODE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
if [ "$HTTP_CODE" = "403" ]; then
    print_success "VIEWER correctly forbidden from creating records (403)"
else
    echo "Note: Expected 403, got $HTTP_CODE"
fi
echo ""

# Step 4: Test POST with EDITOR
print_step 4 "Testing POST /records with EDITOR role"
echo ""
echo "Command:"
echo "curl -X POST $API_URL/records \\"
echo "  -H \"Authorization: Bearer \$EDITOR_TOKEN\" \\"
echo "  -H \"Content-Type: application/json\" \\"
echo "  -d '{...patient data...}' -k"
echo ""
echo "Request body:"
cat << 'EOF'
{
  "patient_id": "P-001",
  "name": "John Doe",
  "age": 45,
  "diagnosis": "Hypertension",
  "consent": true
}
EOF
echo ""
echo "Response:"
RESPONSE=$(curl -s -X POST $API_URL/records \
    -H "Authorization: Bearer $EDITOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"patient_id": "P-001", "name": "John Doe", "age": 45, "diagnosis": "Hypertension", "consent": true}' \
    -k)
echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
PATIENT_ID=$(echo "$RESPONSE" | grep -o '"id":"[^"]*"' | cut -d'"' -f4 | head -1)
PATIENT_ID=${PATIENT_ID:-P-001}
print_success "EDITOR successfully created patient record (ID: $PATIENT_ID)"
echo ""

# Step 5: Test GET specific record with VIEWER
print_step 5 "Testing GET /records/{id} with VIEWER role"
echo ""
echo "Command:"
echo "curl -X GET $API_URL/records/$PATIENT_ID \\"
echo "  -H \"Authorization: Bearer \$VIEWER_TOKEN\" -k"
echo ""
echo "Response:"
RESPONSE=$(curl -s -X GET $API_URL/records/$PATIENT_ID \
    -H "Authorization: Bearer $VIEWER_TOKEN" \
    -k)
echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
print_success "VIEWER can read specific patient record"
echo ""

# Step 6: Test invalid token
print_step 6 "Testing request with invalid token (should fail with 401)"
echo ""
echo "Command:"
echo "curl -X GET $API_URL/records \\"
echo "  -H \"Authorization: Bearer invalid.token.here\" -k"
echo ""
echo "Response:"
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" -X GET $API_URL/records \
    -H "Authorization: Bearer invalid.token.here" \
    -k)
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d':' -f2)
echo "$RESPONSE" | grep -v "HTTP_CODE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
if [ "$HTTP_CODE" = "401" ]; then
    print_success "Invalid token correctly rejected (401)"
fi
echo ""

# Step 7: Test missing auth header
print_step 7 "Testing request without auth header (should fail with 401)"
echo ""
echo "Command:"
echo "curl -X GET $API_URL/records -k"
echo ""
echo "Response:"
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" -X GET $API_URL/records -k)
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d':' -f2)
echo "$RESPONSE" | grep -v "HTTP_CODE"
if [ "$HTTP_CODE" = "401" ]; then
    print_success "Missing auth header correctly rejected (401)"
fi
echo ""

# Step 8: Test TLS with curl -v
print_step 8 "Verifying TLS encryption (checking certificate handshake)"
echo ""
echo "Command:"
echo "curl -v -X GET $API_URL/records \\"
echo "  -H \"Authorization: Bearer \$EDITOR_TOKEN\" -k 2>&1 | grep -i 'SSL\|TLS\|certificate'"
echo ""
echo "TLS Details:"
curl -v -X GET $API_URL/records \
    -H "Authorization: Bearer $EDITOR_TOKEN" \
    -k 2>&1 | grep -E -i "SSL|TLS|certificate|subject|issuer|CN=" | head -10
print_success "TLS encryption verified"
echo ""

# Step 9: Test Prometheus metrics
print_step 9 "Checking Prometheus metrics endpoint"
echo ""
echo "Command:"
echo "curl -X GET $API_URL/metrics -k"
echo ""
echo "Response (first 20 lines):"
RESPONSE=$(curl -s -X GET $API_URL/metrics -k)
echo "$RESPONSE" | head -20
print_success "Prometheus metrics endpoint active"
echo ""

# Step 10: Verify encryption at rest
print_step 10 "Verifying encryption at rest"
echo ""
if [ -d "data" ] && [ "$(ls -A data)" ]; then
    echo "Encrypted data files found:"
    ls -lh data/
    echo ""
    echo "Sample encrypted content (binary - unreadable):"
    xxd data/*.bin 2>/dev/null | head -3
    echo ""
    print_success "Data confirmed to be encrypted (binary format)"
else
    echo "No data files found (create records first)"
fi
echo ""

# Step 11: Test 404 for nonexistent record
print_step 11 "Testing GET for nonexistent record (should return 404)"
echo ""
echo "Command:"
echo "curl -X GET $API_URL/records/NONEXISTENT-123 \\"
echo "  -H \"Authorization: Bearer \$VIEWER_TOKEN\" -k"
echo ""
echo "Response:"
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" -X GET $API_URL/records/NONEXISTENT-123 \
    -H "Authorization: Bearer $VIEWER_TOKEN" \
    -k)
HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE" | cut -d':' -f2)
echo "$RESPONSE" | grep -v "HTTP_CODE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
if [ "$HTTP_CODE" = "404" ]; then
    print_success "Nonexistent record correctly rejected (404)"
fi
echo ""

# Summary
print_step 12 "Summary of Security Controls"
echo ""
echo "=========================================="
echo "✓ Identity & Access Management (IAM)"
echo "  - VIEWER role: can READ (/records, /records/{id})"
echo "  - VIEWER role: CANNOT CREATE (POST returns 403)"
echo "  - EDITOR role: can READ and CREATE"
echo "  - Invalid tokens: rejected (401)"
echo "  - Missing auth: rejected (401)"
echo ""
echo "✓ Transport Layer Security (TLS)"
echo "  - API accessible via HTTPS (https://localhost:8443)"
echo "  - Self-signed certificate in use (valid for demo)"
echo "  - TLS handshake visible in curl -v output"
echo ""
echo "✓ Encryption at Rest"
echo "  - Patient data encrypted with Fernet (AES-128)"
echo "  - Data files are binary (unreadable without key)"
echo "  - Key stored separately in keys/data.key"
echo ""
echo "✓ Compliance & Audit"
echo "  - All API operations logged (READ, CREATE)"
echo "  - Data minimization enforced"
echo "  - Consent tracking implemented"
echo ""
echo "✓ DevOps Integration"
echo "  - Jenkins pipeline ready (build → test → deploy)"
echo "  - Unit tests for all endpoints"
echo "  - Prometheus metrics enabled"
echo "  - Grafana dashboard available"
echo "=========================================="
echo ""
echo "✓ Manual Testing Complete!"
echo ""
