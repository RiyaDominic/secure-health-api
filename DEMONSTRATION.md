# Secure Patient Records API - End-to-End Demonstration

This project demonstrates a production-grade secure healthcare microservice with comprehensive security, compliance, and DevOps integration.

## Overview

The Secure Patient Records API is a microservice that showcases:

### 🔐 Security Features
- **Identity & Access Management (IAM)**
  - OpenID Connect / OIDC with Keycloak
  - Role-Based Access Control (RBAC)
  - Two roles: `viewer` (read-only) and `editor` (read/write)

- **Transport Layer Security (TLS)**
  - HTTPS (TLS 1.2+) for all API communications
  - Self-signed certificates for demo (can use CA-signed in production)
  - Verifiable via TLS handshake inspection

- **Data Encryption at Rest**
  - AES-128 encryption via Fernet
  - Encryption key file: `keys/data.key`
  - Data stored as binary blobs in `data/` directory
  - Cannot be accessed without the correct key

### ✅ Compliance & Audit
- Comprehensive audit logging of all operations
- Data minimization (only necessary fields)
- Consent tracking & enforcement
- HIPAA-aligned controls

### 🚀 DevOps Integration
- Jenkins CI/CD pipeline (build → test → deploy)
- Docker containerization with compose orchestration
- Prometheus metrics collection
- Grafana dashboard visualization
- Unit tests for all API endpoints

## Quick Start

### Prerequisites
- Docker & Docker Compose
- curl (for API testing)
- Python 3.11+ (for local development)
- Windows, macOS, or Linux

### Step 1: Start the Services

```bash
# Start all Docker services
docker-compose up -d

# Verify all services are running
docker-compose ps
```

Expected services:
- **Keycloak** (http://localhost:8081) - IAM/OIDC provider
- **API** (https://localhost:8443) - Secure Patient Records API
- **Prometheus** (http://localhost:9090) - Metrics
- **Grafana** (http://localhost:3000) - Dashboard

### Step 2: Run the Automated Demo

**On Windows:**
```bash
.\demo_workflow.bat
```

**On macOS/Linux:**
```bash
bash demo_workflow.sh
```

This script will automatically:
1. Set up Keycloak realm and users
2. Create test users (viewer and editor)
3. Generate JWT tokens
4. Test RBAC enforcement
5. Verify encryption in transit and at rest
6. Display comprehensive security verification

## Manual API Testing

### 1. Get Authentication Tokens

**Viewer Token (read-only):**
```bash
curl -X POST http://localhost:8081/realms/health/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=health-api" \
  -d "username=lab_viewer" \
  -d "password=viewer123" \
  -d "grant_type=password"
```

**Editor Token (read/write):**
```bash
curl -X POST http://localhost:8081/realms/health/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=health-api" \
  -d "username=lab_editor" \
  -d "password=editor123" \
  -d "grant_type=password"
```

### 2. API Endpoints

#### Get All Patient Records
```bash
curl -k -X GET https://localhost:8443/records \
  -H "Authorization: Bearer $VIEWER_TOKEN"
```

#### Create Patient Record (Editor Only)
```bash
curl -k -X POST https://localhost:8443/records \
  -H "Authorization: Bearer $EDITOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "P001",
    "name": "John Doe",
    "age": 45,
    "diagnosis": "Hypertension",
    "consent": true
  }'
```

#### Get Specific Patient Record
```bash
curl -k -X GET https://localhost:8443/records/P001 \
  -H "Authorization: Bearer $VIEWER_TOKEN"
```

#### Get Prometheus Metrics
```bash
curl -k https://localhost:8443/metrics
```

### 3. Test RBAC Enforcement

**Viewer Trying to Create (Should Fail with 403):**
```bash
curl -k -X POST https://localhost:8443/records \
  -H "Authorization: Bearer $VIEWER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Test", "age": 30}'

# Expected: {"error": "forbidden"}
```

**Editor Creating Successfully:**
```bash
curl -k -X POST https://localhost:8443/records \
  -H "Authorization: Bearer $EDITOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "Jane Smith", "age": 35, "consent": true}'

# Expected: {"id": "patient-uuid"}
```

## Using Postman
1. Import `Postman_Collection.json` into Postman
2. Ensure environment variables for tokens are set
3. Run the test collections to verify security controls

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Client (Postman/curl)               │
└──────────────────────┬──────────────────────────────────┘
                       │ HTTPS (TLS)
                       ▼
┌─────────────────────────────────────────────────────────┐
│          Flask Microservice (port 8443)                 │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Routes:                                          │   │
│  │ - GET  /records           (viewer, editor)      │   │
│  │ - POST /records           (editor only)         │   │
│  │ - GET  /records/<id>      (viewer, editor)      │   │
│  │ - GET  /metrics           (prometheus)          │   │
│  └──────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Security Layers:                                 │   │
│  │ - JWT Verification (verify_jwt decorator)       │   │
│  │ - RBAC (require_roles decorator)                │   │
│  │ - Audit Logging (all operations)                │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────┬──────────────────────────────────┘
          ┌────────────┼────────────┐
          ▼            ▼            ▼
    ┌──────────┐ ┌──────────┐ ┌──────────┐
    │ Keycloak │ │ Storage  │ │ Metrics  │
    │ (OIDC)   │ │ (AES)    │ │(Prom)    │
    └──────────┘ └──────────┘ └──────────┘
```

## File Structure

```
secure-health-api/
├── app/
│   ├── server.py              # Flask API routes
│   ├── auth.py                # JWT verification & RBAC
│   ├── storage.py             # AES encryption & data layer
│   ├── compliance.py          # Audit logging & compliance
│   ├── requirements.txt        # Python dependencies
│   ├── Dockerfile             # Container definition
│   └── tests/
│       └── test_api.py        # Unit tests (GET, POST, GET all)
├── certs/
│   ├── server.crt             # TLS certificate
│   └── server.key             # TLS private key
├── keys/
│   └── data.key               # AES encryption key
├── data/                      # Encrypted patient records
├── docker-compose.yml         # Service orchestration
├── Jenkinsfile                # CI/CD pipeline
├── demo_workflow.sh           # Linux/macOS demo script
├── demo_workflow.bat          # Windows demo script
├── Postman_Collection.json    # API test collection
└── README.md                  # This file
```

## Security Verification Checklist

### ✅ Identity & Access Management
- [ ] Create test users with different roles
- [ ] Viewer can READ records
- [ ] Viewer CANNOT CREATE records
- [ ] Editor can READ and CREATE records
- [ ] Invalid tokens are rejected (401)
- [ ] Missing auth headers are rejected (401)

### ✅ Transport Layer Security (TLS)
- [ ] Curl with `-k` flag succeeds (self-signed cert)
- [ ] HTTPS endpoint: `https://localhost:8443`
- [ ] `curl -v` shows TLS handshake
- [ ] Certificate details visible in browser dev tools

### ✅ Encryption at Rest
- [ ] Data files in `data/` directory are binary
- [ ] Files cannot be read directly
- [ ] Only readable via API with correct key
- [ ] Key `keys/data.key` is separate from code

### ✅ Compliance & Audit
- [ ] All API operations logged
- [ ] Audit log includes user, action, resource
- [ ] Data minimization enforced
- [ ] Consent tracking implemented

### ✅ DevOps Integration
- [ ] Unit tests pass: `pytest app/tests/test_api.py`
- [ ] Jenkins pipeline builds image
- [ ] Tests run in container
- [ ] Metrics endpoint active
- [ ] Prometheus scrapes metrics

## Common Tasks

### Run Unit Tests
```bash
# Inside container
docker-compose exec app python -m pytest app/tests/test_api.py -v

# Or locally (with dependencies installed)
pytest app/tests/test_api.py -v
```

### View Application Logs
```bash
docker-compose logs -f app
```

### Rebuild API Container
```bash
docker-compose build app
docker-compose up -d app
```

### Access Keycloak Admin Console
```
URL: http://localhost:8081/admin/
Username: admin
Password: admin
```

### View Prometheus Dashboard
```
URL: http://localhost:9090/
Query metrics like: api_requests_total, api_request_latency_seconds
```

### View Grafana Dashboard
```
URL: http://localhost:3000/
Username: admin
Password: admin (or as per compose config)
```

### Inspect Encrypted Data
```bash
# Files are binary - not human readable
hexdump -C data/*.bin

# Or with Python
python -c "
import json
from cryptography.fernet import Fernet
with open('keys/data.key', 'rb') as f:
    key = f.read()
cipher = Fernet(key)
with open('data/patient-id.bin', 'rb') as f:
    enc = f.read()
dec = cipher.decrypt(enc)
print(json.loads(dec.decode('utf-8')))
"
```

## Production Considerations

While this is a demonstration, production deployments should include:

1. **SSL/TLS**
   - Use CA-signed certificates (not self-signed)
   - Enable certificate pinning in mobile apps
   - Implement certificate rotation

2. **Key Management**
   - Use external key management service (AWS KMS, Azure Key Vault)
   - Implement key rotation policies
   - Secure key distribution

3. **Database**
   - Replace file-based storage with PostgreSQL/MySQL
   - Enable database encryption
   - Implement connection pooling

4. **OIDC Provider**
   - Use managed OIDC service (Auth0, Okta, Azure AD)
   - Implement MFA
   - Set up proper audit trails

5. **Monitoring**
   - Set up alerting (PagerDuty, Slack)
   - Implement security event monitoring
   - Archive audit logs (Splunk, ELK Stack)

6. **CI/CD**
   - Integrate SAST/DAST tools
   - Implement container image scanning
   - Set up deployment approvals

## Troubleshooting

### Keycloak Not Starting
```bash
docker-compose down
docker-compose up -d keycloak
docker-compose logs keycloak
```

### API Connection Refused
```bash
docker-compose ps  # Check if app container is running
docker-compose logs app  # Check for errors
docker-compose up --build app  # Rebuild
```

### Certificate Errors
- Use `curl -k` to skip certificate verification (demo only)
- Check certs exist: `ls -la certs/`
- Check paths in `server.py`

### Token Not Working
- Verify Keycloak is running: `curl http://localhost:8081`
- Check realm exists in Keycloak admin console
- Verify user exists and role is assigned
- Check token expiration (default 1 hour)

### Database Issues
- Files should be in `data/` directory
- Check file permissions: `ls -la data/`
- Verify `keys/data.key` exists and is readable
- Python `cryptography` package must be installed

## Learning Outcomes

Students completing this demonstration can:

1. ✅ **Test secure workflow choreography using Postman/curl**
   - Understanding HTTP/HTTPS patterns
   - JWT token handling
   - Request/response structures

2. ✅ **Prove security and compliance**
   - IAM enforces RBAC (viewer vs editor)
   - TLS encrypts traffic in transit
   - AES encrypts data at rest
   - Audit logging tracks all operations

3. ✅ **Demonstrate DevOps integration**
   - Jenkins pipeline automates build/test/deploy
   - Docker standardizes deployment
   - Prometheus metrics enable monitoring
   - Grafana visualizes performance

4. ✅ **Reflect real-world healthcare workflow**
   - Production-grade security patterns
   - Compliance-focused design
   - Microservice architecture
   - Risk management approach

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [HIPAA Security Rule](https://www.hhs.gov/hipaa/for-professionals/security/index.html)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [Flask Security Best Practices](https://flask.palletsprojects.com/en/2.3.x/security/)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8949)
- [Docker Security](https://docs.docker.com/engine/security/)

## License

This is an educational project for demonstration purposes.

## Support

For questions or issues:
1. Check logs: `docker-compose logs app`
2. Verify services: `docker-compose ps`
3. Review demonstration script output
4. Check application imports and dependencies
