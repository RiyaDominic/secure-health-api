# Secure Patient Records API - Quick Reference Card

## 🚀 Getting Started (30 seconds)

```bash
# Start services
docker-compose up -d

# Run demonstration
.\demo_workflow.bat          # Windows
bash demo_workflow.sh        # Linux/Mac

# Done! See results
```

## 🔗 URLs & Credentials

| Service | URL | Username | Password |
|---------|-----|----------|----------|
| API | https://localhost:8443 | - | - |
| Keycloak Admin | http://localhost:8081/admin/ | admin | admin |
| Prometheus | http://localhost:9090 | - | - |
| Grafana | http://localhost:3000 | admin | admin |

## 👤 Test User Credentials

| User | Username | Password | Role | Can DO |
|------|----------|----------|------|--------|
| Viewer | lab_viewer | viewer123 | viewer | READ only |
| Editor | lab_editor | editor123 | editor | READ + CREATE |

## 📝 API Endpoints

```bash
# Get JWT Token (Viewer)
curl -X POST http://localhost:8081/realms/health/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=health-api&username=lab_viewer&password=viewer123&grant_type=password"

# Get JWT Token (Editor)
curl -X POST http://localhost:8081/realms/health/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=health-api&username=lab_editor&password=editor123&grant_type=password"

# Get All Records
curl -k -X GET https://localhost:8443/records \
  -H "Authorization: Bearer $TOKEN"

# Create Patient Record (Editor Only)
curl -k -X POST https://localhost:8443/records \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"patient_id":"P001","name":"John Doe","age":45,"consent":true}'

# Get Specific Patient
curl -k -X GET https://localhost:8443/records/P001 \
  -H "Authorization: Bearer $TOKEN"

# Get Prometheus Metrics
curl -k https://localhost:8443/metrics
```

## 🧪 Testing

```bash
# Run automated demo
.\demo_workflow.bat              # Windows
bash demo_workflow.sh            # Linux/Mac

# Run manual step-by-step tests
.\test_manual.ps1               # Windows PowerShell
bash test_manual.sh             # Linux/Mac

# Run unit tests
docker-compose exec app python -m pytest app/tests/test_api.py -v

# Use Postman
Import Postman_Collection.json
```

## 📊 Docker Commands

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View status
docker-compose ps

# View logs (all)
docker-compose logs -f

# View specific service logs
docker-compose logs -f app
docker-compose logs -f keycloak

# Rebuild
docker-compose build app
docker-compose up -d app

# Execute command in container
docker-compose exec app python -m pytest app/tests/test_api.py -v
```

## 🔐 Security Verification Checklist

- [ ] **IAM/RBAC**
  - [ ] Viewer can read: `curl -k -X GET .../records -H "Authorization: Bearer $VIEWER_TOKEN"`
  - [ ] Viewer blocked from write: `curl -k -X POST .../records -H "Authorization: Bearer $VIEWER_TOKEN"` → 403
  - [ ] Editor can write: `curl -k -X POST .../records -H "Authorization: Bearer $EDITOR_TOKEN"` → 201

- [ ] **TLS**
  - [ ] HTTPS works: `curl -k https://localhost:8443/records`
  - [ ] Certificate visible: `curl -v https://localhost:8443/records 2>&1 | grep -i SSL`

- [ ] **Encryption at Rest**
  - [ ] Files encrypted: `ls -la data/` (binary .bin files)
  - [ ] Not readable: `cat data/*.bin` (binary output)

- [ ] **Tests Pass**
  - [ ] Unit tests: `docker-compose exec app python -m pytest app/tests/test_api.py -v` → 8 passed

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| Keycloak won't start | `docker-compose logs keycloak` Check for errors, wait 30s |
| API connection refused | `docker-compose ps app` Check if running, rebuild: `docker-compose build app` |
| Token not working | Verify realm in Keycloak admin, user exists, role assigned |
| Certificate error | Use `-k` flag: `curl -k https://localhost:8443/...` |
| pytest not found | Update requirements.txt, rebuild: `docker-compose build app` |

## 📂 Important Files

```
secure-health-api/
├── app/
│   ├── server.py              ← Main API routes
│   ├── auth.py                ← JWT & RBAC
│   ├── storage.py             ← Encryption
│   ├── compliance.py          ← Audit logging
│   └── tests/test_api.py      ← 8 unit tests
├── certs/server.crt/.key      ← HTTPS certificates
├── keys/data.key              ← Encryption key
├── docker-compose.yml         ← Service orchestration
├── demo_workflow.bat/.sh      ← Automated demo
├── test_manual.ps1/.sh        ← Manual tests
├── Postman_Collection.json    ← API test suite
├── SETUP.md                   ← Quick start
└── DEMONSTRATION.md           ← Full docs
```

## 🎯 Expected Demo Output

```
✓ Keycloak realm created
✓ Test users (viewer, editor) created
✓ JWT tokens obtained
✓ VIEWER can read records
✓ VIEWER blocked from creating (403)
✓ EDITOR can create records (201)
✓ EDITOR can read records (200)
✓ TLS encryption verified
✓ AES encryption at rest confirmed
✓ Unit tests pass (8/8)
✓ Prometheus metrics active
```

## 💡 Pro Tips

1. **Save Token to Variable (Bash/PowerShell)**
   ```bash
   # Bash
   VIEWER_TOKEN=$(curl -s ... | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)
   
   # PowerShell
   $TOKEN = (Invoke-WebRequest -Uri ... | ConvertFrom-Json).access_token
   ```

2. **Format JSON Response**
   ```bash
   curl -s ... | python3 -m json.tool  # or jq
   ```

3. **Check Certificate**
   ```bash
   openssl x509 -in certs/server.crt -text -noout
   ```

4. **Decode JWT Token**
   ```bash
   # Online: jwt.io
   # Or use jq to decode base64 parts
   ```

5. **Monitor API in Real-Time**
   ```bash
   while true; do
     curl -s -k https://localhost:8443/metrics | grep api_requests_total
     sleep 5
   done
   ```

## 🎓 Learning Path

1. **Start Here:** Read SETUP.md (5 min)
2. **Run Demo:** `demo_workflow.bat/.sh` (5-10 min)
3. **Manual Test:** `test_manual.ps1/.sh` (10 min)
4. **Postman Tests:** Import collection, run requests (15 min)
5. **Inspect Code:** Review server.py, auth.py, storage.py (20 min)
6. **Run Unit Tests:** `pytest` (5 min)
7. **Review Logs:** `docker-compose logs` (5 min)

**Total Time:** ~60 minutes to complete, understand, and verify all security controls

## 📞 Key Contacts

- **Framework Issues:** Flask docs (https://flask.palletsprojects.com)
- **JWT Issues:** PyJWT docs (https://pyjwt.readthedocs.io)
- **Encryption:** Cryptography docs (https://cryptography.io)
- **Docker:** Docker docs (https://docs.docker.com)
- **Keycloak:** Keycloak docs (https://www.keycloak.org/documentation)

## ⚡ One-Liner Demonstrations

```bash
# Get viewer token and save
VIEWER_TOKEN=$(curl -s -X POST http://localhost:8081/realms/health/protocol/openid-connect/token -H "Content-Type: application/x-www-form-urlencoded" -d "client_id=health-api&username=lab_viewer&password=viewer123&grant_type=password" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

# Test viewer can read
curl -k -X GET https://localhost:8443/records -H "Authorization: Bearer $VIEWER_TOKEN"

# Test viewer blocked from write
curl -k -X POST https://localhost:8443/records -H "Authorization: Bearer $VIEWER_TOKEN" -H "Content-Type: application/json" -d '{"name":"test"}' -w "\n%{http_code}\n"

# Get editor token and save
EDITOR_TOKEN=$(curl -s -X POST http://localhost:8081/realms/health/protocol/openid-connect/token -H "Content-Type: application/x-www-form-urlencoded" -d "client_id=health-api&username=lab_editor&password=editor123&grant_type=password" | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

# Test editor can create
curl -k -X POST https://localhost:8443/records -H "Authorization: Bearer $EDITOR_TOKEN" -H "Content-Type: application/json" -d '{"name":"John","age":45,"consent":true}'

# View encrypted data (non-human readable)
hexdump -C data/*.bin | head -5

# Run tests
docker-compose exec app python -m pytest app/tests/test_api.py::test_minimize -v
```

---

**⭐ Everything Ready!** Run `demo_workflow.bat` (Windows) or `bash demo_workflow.sh` (Linux/Mac) to begin!
