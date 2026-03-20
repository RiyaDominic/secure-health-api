# 🔐 Secure Patient Records API

A production-grade healthcare microservice demonstrating end-to-end security, compliance, and DevOps integration.

## Quick Start (30 seconds)

```bash
# Start services
docker-compose up -d

# Run demonstration
.\demo_workflow.bat          # Windows
bash demo_workflow.sh        # Linux/macOS
```

This runs a fully automated demonstration showing secure IAM, TLS encryption, AES encryption at rest, and comprehensive audit logging—all in 5-10 minutes.

---

## Overview

The Secure Patient Records API is a complete microservice that showcases:

### 🔐 **Security Features**
- **Identity & Access Management (IAM)** - OIDC with Keycloak, JWT tokens, RBAC
- **Transport Layer Security (TLS)** - HTTPS with self-signed certificates
- **Encryption at Rest** - AES-128 (Fernet) for patient data
- **Compliance & Audit** - Operation logging, user tracking, consent enforcement

### ✅ **Compliance**
- Audit trails for all operations
- Data minimization (only necessary fields)
- Consent validation
- HIPAA-aligned controls

### 🚀 **DevOps Integration**
- Docker containerization
- Jenkins CI/CD pipeline (build → test → deploy)
- Prometheus metrics & Grafana dashboards
- Comprehensive unit tests (8 tests for all endpoints)

### 📚 **API Endpoints**
| Method | Endpoint | Role | Purpose |
|--------|----------|------|---------|
| GET | `/records` | viewer, editor | List all patient records |
| POST | `/records` | editor | Create new patient record |
| GET | `/records/{id}` | viewer, editor | Get specific patient |
| GET | `/metrics` | public | Prometheus metrics |

---

## Prerequisites

- Docker & Docker Compose
- curl (for manual testing)
- Windows 10+, macOS, or Linux
- ~4GB free disk space

---

## Installation & Demo

### Step 1: Start Services
```bash
docker-compose up -d
docker-compose ps  # Verify all services running
```

### Step 2: Run Automated Demo

**Windows:**
```bash
.\demo_workflow.bat
```

**Linux/macOS:**
```bash
bash demo_workflow.sh
```

### What the Demo Does
✓ Sets up Keycloak realm with test users  
✓ Creates viewer (read-only) and editor (read+write) roles  
✓ Generates JWT tokens  
✓ Tests RBAC enforcement (viewer blocked from writing)  
✓ Verifies TLS encryption in transit  
✓ Confirms AES encryption at rest  
✓ Runs unit tests (8 pass)  
✓ Displays comprehensive security verification  

---

## Test Users

| User | Password | Role | Can Do |
|------|----------|------|--------|
| lab_viewer | viewer123 | viewer | READ only |
| lab_editor | editor123 | editor | READ + CREATE |

---

## Manual API Testing

### Get Tokens

**Viewer Token:**
```bash
curl -X POST http://localhost:8081/realms/health/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=health-api&username=lab_viewer&password=viewer123&grant_type=password"
```

**Editor Token:**
```bash
curl -X POST http://localhost:8081/realms/health/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=health-api&username=lab_editor&password=editor123&grant_type=password"
```

### API Calls

```bash
# Get all records (viewer, editor)
curl -k -X GET https://localhost:8443/records \
  -H "Authorization: Bearer $TOKEN"

# Create record (editor only)
curl -k -X POST https://localhost:8443/records \
  -H "Authorization: Bearer $EDITOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"patient_id":"P001","name":"John Doe","age":45,"consent":true}'

# Get specific record (viewer, editor)
curl -k -X GET https://localhost:8443/records/P001 \
  -H "Authorization: Bearer $TOKEN"

# Prometheus metrics
curl -k https://localhost:8443/metrics
```

### Test RBAC Enforcement

```bash
# Viewer trying to create (should fail with 403)
curl -k -X POST https://localhost:8443/records \
  -H "Authorization: Bearer $VIEWER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"test"}'
# Expected: {"error": "forbidden"}
```

---

## Testing Methods

### Automated (Recommended)
```bash
# Windows
.\demo_workflow.bat

# Linux/macOS
bash demo_workflow.sh
```
**Time:** 5-10 minutes | Shows everything automatically

### Manual Step-by-Step
```bash
# Windows PowerShell
.\test_manual.ps1

# Linux/macOS
bash test_manual.sh
```
**Time:** 15 minutes | Detailed curl examples with explanations

### Unit Tests
```bash
docker-compose exec app python -m pytest app/tests/test_api.py -v
```
**Result:** 8 tests pass, covering all endpoints and auth scenarios

### Postman GUI
1. Import `Postman_Collection.json` into Postman
2. Set environment variables for tokens
3. Run test collections with visual results

---

## Project Structure

```
secure-health-api/
├── app/
│   ├── server.py                    # Flask API (3 endpoints)
│   ├── auth.py                      # JWT & RBAC
│   ├── storage.py                   # AES encryption
│   ├── compliance.py                # Audit logging
│   ├── requirements.txt              # Dependencies
│   ├── Dockerfile                   # Container config
│   └── tests/test_api.py            # 8 unit tests
├── certs/                           # TLS certificates
│   ├── server.crt
│   └── server.key
├── keys/
│   └── data.key                     # AES encryption key
├── data/                            # Encrypted patient records
├── docker-compose.yml               # Service orchestration
├── Jenkinsfile                      # CI/CD pipeline
├── Postman_Collection.json          # API test suite
├── demo_workflow.bat/.sh            # Automated demo
├── test_manual.ps1/.sh              # Manual testing
├── README.md                        # This file
├── SETUP.md                         # Quick start guide
└── DEMONSTRATION.md                 # Detailed documentation
```

---

## Architecture

```
┌──────────────────────────────────────────┐
│        Client (curl, Postman)            │
└────────────────┬─────────────────────────┘
                 │ HTTPS (TLS)
                 ▼
┌──────────────────────────────────────────┐
│    Flask API (https://localhost:8443)    │
│  • JWT verification (@verify_jwt)        │
│  • RBAC enforcement (@require_roles)     │
│  • Audit logging (audit_log)             │
└────┬──────────────┬──────────────┬───────┘
     │              │              │
     ▼              ▼              ▼
┌─────────┐  ┌──────────┐  ┌──────────────┐
│Keycloak │  │AES Enc.  │  │Prometheus    │
│(OIDC)   │  │Storage   │  │Metrics       │
└─────────┘  └──────────┘  └──────────────┘
```

---

## Security Verification

### ✅ Identity & Access Management
```bash
# Viewer can read
curl -k https://localhost:8443/records -H "Authorization: Bearer $VIEWER_TOKEN"
# Result: 200 OK, list of records

# Viewer blocked from writing
curl -k -X POST https://localhost:8443/records -H "Authorization: Bearer $VIEWER_TOKEN" ...
# Result: 403 Forbidden
```

### ✅ Transport Layer Security (TLS)
```bash
# HTTPS endpoint
curl -k https://localhost:8443/records

# View certificate details
curl -v https://localhost:8443/records 2>&1 | grep -i SSL
```

### ✅ Encryption at Rest
```bash
# Encrypted files are binary
ls -la data/
hexdump -C data/*.bin
# Result: Unreadable binary data
```

### ✅ Audit Logging
Configuration in `compliance.py` logs all operations:
- User identity
- Action type (READ, CREATE)
- Patient ID
- Timestamp

### ✅ Unit Tests
```bash
docker-compose exec app python -m pytest app/tests/test_api.py -v
# Result: 8 passed
```

---

## Access Monitoring Dashboards

### Prometheus
- **URL:** http://localhost:9090
- **Query:** `api_requests_total` shows API request metrics

### Grafana
- **URL:** http://localhost:3000
- **Username/Password:** admin/admin
- Create dashboards to visualize metrics

### Keycloak Admin Console
- **URL:** http://localhost:8081/admin/
- **Username/Password:** admin/admin
- Manage users, roles, tokens

---

## Common Commands

```bash
# Docker
docker-compose up -d            # Start services
docker-compose down             # Stop services
docker-compose ps               # View status
docker-compose logs -f app      # Watch app logs
docker-compose build app        # Rebuild app

# Tests
docker-compose exec app python -m pytest app/tests/test_api.py -v

# API (save token first)
export TOKEN=$(curl -s ... | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
curl -k https://localhost:8443/records -H "Authorization: Bearer $TOKEN"
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Keycloak won't start | Check logs: `docker-compose logs keycloak` |
| API connection refused | Verify running: `docker-compose ps app` |
| Token not working | Ensure realm exists, user has role assigned |
| Certificate errors | Use `-k` flag: `curl -k https://...` |
| Tests fail | Check imports: `docker-compose exec app python -m pytest -v` |

See [SETUP.md](SETUP.md) for detailed troubleshooting.

---

## Assignment Requirements - Status

| Requirement | Status | Details |
|-------------|--------|---------|
| Backend Database | ✅ | File-based with AES encryption |
| Patient Microservice | ✅ | Flask with 3 endpoints |
| IAM/RBAC | ✅ | 2 test users, 2 roles |
| TLS Encryption | ✅ | HTTPS on port 8443 |
| AES Encryption | ✅ | Fernet cipher, binary storage |
| Compliance & Audit | ✅ | Operation logging |
| Jenkins Pipeline | ✅ | Build → Test → Deploy |
| Unit Tests | ✅ | 8 tests, all passing |

---

## Documentation

- **[README.md](README.md)** (this file) - Overview and quick reference
- **[SETUP.md](SETUP.md)** - Step-by-step setup guide
- **[DEMONSTRATION.md](DEMONSTRATION.md)** - Complete API documentation
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** - Command reference card
- **[IMPLEMENTATION_SUMMARY.md](IMPLEMENTATION_SUMMARY.md)** - Technical details
- **[PROJECT_COMPLETION.md](PROJECT_COMPLETION.md)** - Completion summary

---

## Key Files

### Application Code
- `app/server.py` - Flask API with 3 endpoints + metrics
- `app/auth.py` - JWT verification & RBAC decorators
- `app/storage.py` - AES encryption/decryption
- `app/compliance.py` - Audit logging
- `app/tests/test_api.py` - 8 comprehensive unit tests

### Configuration
- `docker-compose.yml` - Keycloak, API, Prometheus, Grafana
- `Dockerfile` - Python 3.11 + Flask + pytest
- `Jenkinsfile` - CI/CD pipeline

### Testing
- `demo_workflow.bat/.sh` - Automated end-to-end demo
- `test_manual.ps1/.sh` - Step-by-step manual testing
- `Postman_Collection.json` - 20+ API tests

---

## What You'll Learn

✅ Secure microservice architecture
✅ JWT and OIDC authentication
✅ Role-based access control (RBAC)
✅ TLS/SSL encryption
✅ AES encryption implementation
✅ Docker containerization
✅ CI/CD pipelines
✅ Prometheus monitoring
✅ Security testing
✅ Healthcare compliance patterns

---

## Next Steps

1. **Quick Demo:** `.\demo_workflow.bat` (Windows) or `bash demo_workflow.sh` (Linux/macOS)
2. **Detailed Guide:** Read [SETUP.md](SETUP.md)
3. **API Reference:** See [DEMONSTRATION.md](DEMONSTRATION.md)
4. **Manual Testing:** Run `test_manual.ps1` or `test_manual.sh`
5. **Postman Tests:** Import `Postman_Collection.json`

---

## Support

- **Setup Issues:** See [SETUP.md](SETUP.md#troubleshooting)
- **API Questions:** See [DEMONSTRATION.md](DEMONSTRATION.md)
- **Quick Lookup:** Use [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
- **Code Details:** Check code comments and docstrings

---

## Summary

This is a **complete, production-ready demonstration** of secure healthcare API development including:

- 🔐 Multiple layers of security (TLS + AES + RBAC)
- 📊 Comprehensive testing (8 unit tests + integration tests)
- 📈 DevOps ready (Docker + Jenkins + Prometheus)
- 📝 Well documented (2500+ lines across 6 files)
- 🎯 Real-world patterns (HIPAA-aligned controls)

**Ready to demonstrate? Run:**
```bash
.\demo_workflow.bat      # Windows
bash demo_workflow.sh   # Linux/macOS
```

---

**Last Updated:** March 2026  
**Status:** ✅ Complete and Ready  
**All Tests:** ✅ Passing (8/8)  
**All Requirements:** ✅ Met
