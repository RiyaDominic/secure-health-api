## Secure Patient Records API - Quick Setup & Running the Demonstration

### Prerequisites
- Docker & Docker Compose installed
- Curl installed (for API testing)
- Windows 10+, macOS, or Linux
- ~4GB free disk space

### Directory Structure
```
secure-health-api/
├── app/                          # Flask API application
│   ├── server.py                 # Main routes (GET, POST)
│   ├── auth.py                   # JWT verification & RBAC
│   ├── storage.py                # Encryption at rest (AES)
│   ├── compliance.py             # Audit logging
│   ├── requirements.txt           # Python dependencies
│   ├── Dockerfile                # Container image
│   └── tests/test_api.py         # Unit tests
├── certs/                        # TLS certificates
│   ├── server.crt                # HTTPS certificate
│   └── server.key                # HTTPS private key
├── keys/                         # Encryption keys
│   └── data.key                  # AES encryption key
├── docker-compose.yml            # Service orchestration
├── Jenkinsfile                   # CI/CD pipeline
├── Postman_Collection.json       # API test collection
├── demo_workflow.bat/.sh         # Automated demo scripts
├── test_manual.ps1/.sh           # Manual testing scripts
└── DEMONSTRATION.md              # Full documentation
```

---

## Quick Start (5 Minutes)

### Step 1: Start Services
```bash
cd /path/to/secure-health-api
docker-compose up -d
```

Wait for services to fully start (~30 seconds):
```bash
docker-compose ps
```

Expected output:
```
NAME              IMAGE              STATUS
secure-health-keycloak    quay.io/keycloak/keycloak    Up
secure-health-app        secure-health-api-app         Up
secure-health-prometheus prom/prometheus               Up
secure-health-grafana    grafana/grafana              Up
```

### Step 2: Run Automated Demo

**Windows:**
```bash
.\demo_workflow.bat
```

**macOS/Linux:**
```bash
bash demo_workflow.sh
```

This will:
✓ Set up Keycloak realm, users, and roles
✓ Generate JWT tokens
✓ Test RBAC (viewer vs editor)
✓ Verify TLS encryption
✓ Confirm AES encryption at rest
✓ Display comprehensive security verification

**Demo takes ~5-10 minutes and displays all results.**

---

## What Gets Tested

### 1. Identity & Access Management (IAM)
```
Viewer User (lab_viewer / viewer123):
  ✓ Can READ records (GET /records)
  ✗ Cannot CREATE records (POST blocked, 403)

Editor User (lab_editor / editor123):
  ✓ Can READ records (GET /records)
  ✓ Can CREATE records (POST /records)
```

### 2. Transport Layer Security (TLS)
- API accessible via HTTPS: `https://localhost:8443`
- Certificates: `certs/server.crt` & `certs/server.key`
- Demo script shows TLS handshake

### 3. Encryption at Rest
- Patient data encrypted with Fernet (AES-128)
- Files in `data/` directory are binary (unreadable)
- Key stored separately: `keys/data.key`

### 4. Compliance & Audit
- All operations logged (READ, CREATE, DELETE)
- User, action, and resource tracked
- Data minimization enforced

### 5. DevOps Integration
- Jenkins pipeline (build → test → deploy)
- Unit tests for all endpoints
- Prometheus metrics collected
- Grafana dashboard available

---

## API Endpoints Summary

| Method | Endpoint | Role | Purpose |
|--------|----------|------|---------|
| GET | `/records` | viewer, editor | List all patient records |
| POST | `/records` | editor | Create new patient record |
| GET | `/records/{id}` | viewer, editor | Get specific patient |
| GET | `/metrics` | public | Prometheus metrics |

---

## Manual Testing (Alternative)

If you prefer to test manually with curl:

**Windows PowerShell:**
```powershell
.\test_manual.ps1
```

**Bash:**
```bash
bash test_manual.sh
```

This provides step-by-step curl commands showing all API endpoints.

---

## Using Postman

1. Open Postman
2. Import `Postman_Collection.json`
3. Create environment with:
   - `api_url`: `https://localhost:8443`
   - `keycloak_url`: `http://localhost:8081`
4. Run "Get Viewer Token" request (saves to `viewer_token`)
5. Run "Get Editor Token" request (saves to `editor_token`)
6. Execute test collections:
   - "Patient Records - Viewer Tests"
   - "Patient Records - Editor Tests"
   - "Security Verification"

Postman will show:
✓ Response status codes
✓ Response bodies
✓ Test assertions pass/fail
✓ Metrics over time

---

## Running Unit Tests

```bash
# Run tests in container
docker-compose exec app python -m pytest app/tests/test_api.py -v

# Or using Docker directly
docker run --rm -v %cd%:/app health-api:local python -m pytest app/tests/test_api.py -v
```

Expected output:
```
test_minimize PASSED
test_enforce_consent PASSED
test_enforce_consent_fails PASSED
test_create_patient_endpoint PASSED
test_get_patient_endpoint PASSED
test_get_patient_not_found PASSED
test_get_all_patients_endpoint PASSED
test_missing_auth_header PASSED

========== 8 passed in 0.42s ==========
```

---

## Viewing Application Logs

```bash
# Live logs
docker-compose logs -f app

# Last 50 lines
docker-compose logs --tail=50 app

# Only Keycloak
docker-compose logs -f keycloak

# Only Prometheus
docker-compose logs -f prometheus
```

---

## Accessing Monitoring Dashboards

### Prometheus
- **URL:** http://localhost:9090
- **Default Query:** `api_requests_total`
- Shows API request counts by endpoint and status

### Grafana
- **URL:** http://localhost:3000
- **Username:** admin
- **Password:** admin (or as configured)
- Create dashboards to visualize Prometheus metrics

### Keycloak Admin Console
- **URL:** http://localhost:8081/admin/
- **Username:** admin
- **Password:** admin
- Manage users, roles, tokens

---

## Jenkins Pipeline (CI/CD)

### View Pipeline
```bash
# Jenkins is available at: http://localhost:8081 (conflicting port)
# Or configure Jenkinsfile in your Jenkins instance
```

### Pipeline Stages
1. **Checkout** - Clone repository
2. **Build** - Build Docker image (`docker build -t health-api:local ./app`)
3. **Test** - Run pytest in container
4. **Security basics** - Validate dependencies
5. **Deploy** - Start app with docker-compose

### Manual Pipeline Execution
```bash
# Simulate the pipeline stages
docker build -t health-api:local ./app
docker run --rm -v %cd%:/app health-api:local python -m pytest
docker-compose up -d app
```

---

## Troubleshooting

### Keycloak Connection Refused
```bash
# Check if Keycloak is running
docker-compose ps keycloak

# View logs
docker-compose logs keycloak

# Restart
docker-compose restart keycloak
docker-compose logs -f keycloak
# Wait for "Keycloak 24.0.0 started"
```

### API Connection Refused
```bash
# Ensure app container is running
docker-compose ps app

# Check for errors
docker-compose logs app

# Rebuild and restart
docker-compose build app
docker-compose up -d app
```

### Token Not Working
```bash
# Verify Keycloak is ready
curl http://localhost:8081

# Token endpoint
curl -X POST http://localhost:8081/realms/health/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=health-api&username=lab_viewer&password=viewer123&grant_type=password"

# If error, check realm exists in Keycloak admin console
```

### Certificate Errors
```bash
# Verify certificates exist
ls -la certs/

# Check certificate details
openssl x509 -in certs/server.crt -text -noout

# Demo script uses -k flag (skip certificate check)
```

### Can't Access Encrypted Data
```bash
# Encrypted data is in binary format
hexdump -C data/*.bin

# Can only decrypt with correct key in app
# This is expected behavior
```

---

## Security Demonstration Checklist

Use this checklist to verify all security controls are working:

### IAM / RBAC
- [ ] Viewer can GET /records
- [ ] Editor can GET /records
- [ ] Viewer cannot POST to /records (403 error)
- [ ] Editor can POST to /records (201 success)
- [ ] Invalid token returns 401
- [ ] Missing auth header returns 401

### TLS Encryption
- [ ] HTTPS endpoint works: `https://localhost:8443/records`
- [ ] curl -v shows TLS certificate
- [ ] curl -k bypasses self-signed certificate check
- [ ] Handshake details visible in verbose output

### Encryption at Rest
- [ ] Data directory exists: `data/`
- [ ] Files have `.bin` extension
- [ ] Binary files cannot be human-read
- [ ] Files only readable via API endpoint
- [ ] Key file exists: `keys/data.key`

### Audit & Compliance
- [ ] Audit log shows operation type (READ, CREATE)
- [ ] Audit log shows user ID
- [ ] Audit log shows patient ID
- [ ] Data minimization enforced (check compliance.py)

### DevOps
- [ ] Docker image builds successfully
- [ ] Unit tests pass (8/8)
- [ ] Prometheus metrics endpoint responds
- [ ] Grafana dashboard loads

---

## Next Steps

### To Extend This Demo

1. **Add Database**
   - Replace file-based storage with PostgreSQL
   - Update `storage.py` with database layer

2. **Production Certificates**
   - Replace self-signed certs with CA-signed certificates
   - Configure certificate rotation

3. **Advanced Monitoring**
   - Set up alerting (PagerDuty, Slack)
   - Configure log aggregation (ELK, Splunk)

4. **Additional Security**
   - Implement MFA in Keycloak
   - Add API rate limiting
   - Implement request signing

5. **Data Residency**
   - Configure encryption key rotation
   - Implement data backup/recovery
   - Add compliance reporting

---

## Key Files Overview

### Core Application
- **server.py** - Flask app with 3 endpoints (GET, POST, GET-all)
- **auth.py** - JWT verification, RBAC decorators
- **storage.py** - AES encryption/decryption
- **compliance.py** - Audit logging, data minimization

### Configuration
- **docker-compose.yml** - Services (Keycloak, API, Prometheus, Grafana)
- **Dockerfile** - Python 3.11, Flask, pytest
- **requirements.txt** - Dependencies (pytest, cryptography, pyjwt)
- **Jenkinsfile** - CI/CD pipeline (build, test, deploy)

### Testing
- **test_api.py** - 8 unit tests covering all endpoints
- **Postman_Collection.json** - API test suite with auth
- **demo_workflow.bat/.sh** - End-to-end automation
- **test_manual.ps1/.sh** - Step-by-step manual testing

---

## Support & References

- **OWASP Top 10:** https://owasp.org/www-project-top-ten/
- **HIPAA Security:** https://www.hhs.gov/hipaa/
- **NIST Framework:** https://www.nist.gov/cyberframework
- **Flask Security:** https://flask.palletsprojects.com/security/
- **JWT Best Practices:** https://tools.ietf.org/html/rfc8949
- **Docker Security:** https://docs.docker.com/engine/security/

---

## Summary

This demonstration successfully shows:

✓ **Secure API Design** - HTTPS, JWT, RBAC
✓ **Data Protection** - AES encryption at rest
✓ **Compliance** - Audit trails, data minimization
✓ **DevOps** - CI/CD, containerization, monitoring
✓ **Real-World Patterns** - Healthcare-grade security

The project is ready for student demonstration and can serve as a template for production systems with additional hardening.

---

## End of Setup Guide

For detailed API documentation, see DEMONSTRATION.md
For troubleshooting, see docker-compose logs
