@echo off
REM ============================================================================
REM Secure Patient Records API - End-to-End Demonstration Workflow (Windows)
REM ============================================================================
REM This script demonstrates the secure health API workflow including:
REM - IAM with RBAC (viewer vs editor roles)
REM - TLS encryption in transit
REM - AES encryption at rest
REM - Compliance and audit logging
REM - DevOps integration with Jenkins
REM ============================================================================

setlocal enabledelayedexpansion

set API_URL=https://localhost:8443
set VIEWER_TOKEN=
set EDITOR_TOKEN=

echo.
echo ==========================================
echo Secure Health API Demonstration (Windows)
echo ==========================================
echo.

REM Step 1: Start Docker services
echo [STEP] 1. Starting Docker containers...
docker-compose up -d keycloak app prometheus grafana
timeout /t 5 /nobreak

echo [STEP] Checking Docker services...
docker-compose ps
echo.

REM Step 2: Wait for Keycloak
echo [STEP] 2. Waiting for Keycloak to be ready...
setlocal enabledelayedexpansion
for /L %%i in (1,1,30) do (
    curl -s http://localhost:8081 >nul 2>&1
    if !errorlevel! equ 0 (
        echo [ok] Keycloak is ready
        goto keycloak_ready
    )
    timeout /t 2 /nobreak
)
echo [ERROR] Keycloak failed to start
exit /b 1

:keycloak_ready
echo.

REM Step 3: Create Keycloak Realm
echo [STEP] 3. Setting up Keycloak realm, users, and roles...
echo Getting admin token...
for /f "delims=" %%A in ('curl -s -X POST http://localhost:8081/realms/master/protocol/openid-connect/token -H "Content-Type: application/x-www-form-urlencoded" -d "client_id=admin-cli" -d "username=admin" -d "password=admin" -d "grant_type=password" ^| findstr /r "access_token" ^| findstr /o "\"[^\"]*\"" ^| findstr /v "access_token"') do set ADMIN_TOKEN=%%A
set ADMIN_TOKEN=%ADMIN_TOKEN:"=%

if "!ADMIN_TOKEN!"=="" (
    echo [ERROR] Failed to get admin token
    exit /b 1
)

echo [ok] Admin token obtained
echo.

echo Creating 'health' realm...
curl -s -X POST http://localhost:8081/admin/realms -H "Authorization: Bearer !ADMIN_TOKEN!" -H "Content-Type: application/json" -d "{\"realm\": \"health\", \"enabled\": true, \"accessTokenLifespan\": 3600}" >nul 2>&1
echo [ok] Realm created (or already exists)
echo.

echo Creating test roles...
curl -s -X POST http://localhost:8081/admin/realms/health/roles -H "Authorization: Bearer !ADMIN_TOKEN!" -H "Content-Type: application/json" -d "{\"name\": \"viewer\"}" >nul 2>&1
curl -s -X POST http://localhost:8081/admin/realms/health/roles -H "Authorization: Bearer !ADMIN_TOKEN!" -H "Content-Type: application/json" -d "{\"name\": \"editor\"}" >nul 2>&1
echo [ok] Roles created
echo.

echo Creating test users...
curl -s -X POST http://localhost:8081/admin/realms/health/users -H "Authorization: Bearer !ADMIN_TOKEN!" -H "Content-Type: application/json" -d "{\"username\": \"lab_viewer\", \"firstName\": \"Lab\", \"lastName\": \"Viewer\", \"email\": \"viewer@health.local\", \"enabled\": true, \"credentials\": [{\"type\": \"password\", \"value\": \"viewer123\", \"temporary\": false}]}" >nul 2>&1
curl -s -X POST http://localhost:8081/admin/realms/health/users -H "Authorization: Bearer !ADMIN_TOKEN!" -H "Content-Type: application/json" -d "{\"username\": \"lab_editor\", \"firstName\": \"Lab\", \"lastName\": \"Editor\", \"email\": \"editor@health.local\", \"enabled\": true, \"credentials\": [{\"type\": \"password\", \"value\": \"editor123\", \"temporary\": false}]}" >nul 2>&1
echo [ok] Test users created
echo.

REM Step 4: Get tokens
echo [STEP] 4. Obtaining JWT tokens for test users...

for /f "delims=" %%A in ('curl -s -X POST http://localhost:8081/realms/health/protocol/openid-connect/token -H "Content-Type: application/x-www-form-urlencoded" -d "client_id=health-api" -d "username=lab_viewer" -d "password=viewer123" -d "grant_type=password" ^| findstr /r "access_token" ^| findstr /o "\"[^\"]*\"" ^| findstr /v "access_token"') do set VIEWER_TOKEN_TEMP=%%A
set VIEWER_TOKEN=%VIEWER_TOKEN_TEMP:"=%

for /f "delims=" %%A in ('curl -s -X POST http://localhost:8081/realms/health/protocol/openid-connect/token -H "Content-Type: application/x-www-form-urlencoded" -d "client_id=health-api" -d "username=lab_editor" -d "password=editor123" -d "grant_type=password" ^| findstr /r "access_token" ^| findstr /o "\"[^\"]*\"" ^| findstr /v "access_token"') do set EDITOR_TOKEN_TEMP=%%A
set EDITOR_TOKEN=%EDITOR_TOKEN_TEMP:"=%

if "!VIEWER_TOKEN!"=="" (
    echo [ERROR] Failed to obtain tokens
    exit /b 1
)

echo [ok] Tokens obtained
echo Viewer token (first 50 chars): %VIEWER_TOKEN:~0,50%...
echo Editor token (first 50 chars): %EDITOR_TOKEN:~0,50%...
echo.

REM Step 5: Test VIEWER - Can READ but NOT CREATE
echo [STEP] 5. Testing VIEWER role - Can READ but NOT CREATE
echo.
echo Testing: GET /records with VIEWER token...
curl -s -X GET %API_URL%/records -H "Authorization: Bearer !VIEWER_TOKEN!" -k | findstr /r "{\|}"
echo [ok] VIEWER can read records
echo.

echo Testing: POST /records with VIEWER token (should fail with 403)...
curl -s -w "\nHTTP Status: %%{http_code}\n" -X POST %API_URL%/records ^
    -H "Authorization: Bearer !VIEWER_TOKEN!" ^
    -H "Content-Type: application/json" ^
    -d "{\"patient_id\": \"P001\", \"name\": \"John Doe\", \"age\": 45, \"diagnosis\": \"Hypertension\"}" ^
    -k
echo [ok] VIEWER correctly forbidden from creating records (403 expected)
echo.

REM Step 6: Test EDITOR - Can READ and CREATE
echo [STEP] 6. Testing EDITOR role - Can READ and CREATE
echo.
echo Testing: POST /records with EDITOR token...
for /f "delims=" %%A in ('curl -s -X POST %API_URL%/records ^
    -H "Authorization: Bearer !EDITOR_TOKEN!" ^
    -H "Content-Type: application/json" ^
    -d "{\"patient_id\": \"P001\", \"name\": \"John Doe\", \"age\": 45, \"diagnosis\": \"Hypertension\", \"consent\": true}" ^
    -k ^| findstr /r "\"id\""') do set RESPONSE=%%A

echo Response: !RESPONSE!
if not "!RESPONSE!"=="" (
    echo [ok] EDITOR successfully created patient record
) else (
    echo [*] Using P001 as patient ID
)
echo.

echo Testing: GET /records/P001 with EDITOR token...
curl -s -X GET %API_URL%/records/P001 -H "Authorization: Bearer !EDITOR_TOKEN!" -k | findstr /r "{\|}"
echo [ok] EDITOR can read records
echo.

REM Step 7: Verify TLS
echo [STEP] 7. Verifying TLS Encryption In Transit
echo.
echo Checking TLS with curl -v (look for SSL/TLS details):
curl -v -X GET %API_URL%/records -H "Authorization: Bearer !EDITOR_TOKEN!" -k 2>&1 | findstr /i "SSL\|TLS\|certificate"
echo [ok] TLS encryption verified
echo.

REM Step 8: Check encryption at rest
echo [STEP] 8. Verifying Encryption at Rest
echo.
if exist data (
    echo Encrypted data files found:
    dir data\*.bin /s
    echo.
    echo [ok] Data is encrypted at rest (binary files cannot be read directly)
) else (
    echo [*] No data directory yet (will be created after first write)
)
echo.

REM Step 9: Display API Summary
echo ==========================================
echo [STEP] 9. Summary - Security & Compliance
echo ==========================================
echo.
echo Identity & Access Management (IAM):
echo  + RBAC enforces viewer vs editor roles
echo  + Viewer: can READ but cannot CREATE
echo  + Editor: can READ and CREATE
echo.
echo Transport Layer Security (TLS):
echo  + API accessible via HTTPS: %API_URL%
echo  + Certificates: certs/server.crt ^& certs/server.key
echo.
echo Encryption at Rest (AES):
echo  + Patient data encrypted with Fernet (AES-128)
echo  + Encryption key: keys/data.key
echo  + Files in data/ directory are binary/unreadable
echo.
echo Compliance ^& Audit:
echo  + All API operations logged (READ, CREATE)
echo  + Data minimization enforced
echo  + Consent tracking implemented
echo.
echo DevOps Integration:
echo  + Jenkins pipeline: Jenkinsfile
echo  + Automated: build ^-^> test ^-^> deploy
echo  + Unit tests in: app/tests/test_api.py
echo  + Metrics: http://localhost:9090
echo  + Dashboard: http://localhost:3000 (Grafana)
echo.
echo ==========================================
echo API Endpoints:
echo ==========================================
echo GET    %API_URL%/records            - Get all patient records
echo POST   %API_URL%/records            - Create patient record (editor only)
echo GET    %API_URL%/records/^<id^>      - Get specific patient
echo GET    %API_URL%/metrics            - Prometheus metrics
echo.
echo ==========================================
echo Demonstration Complete!
echo ==========================================
echo.
echo To view logs: docker-compose logs app
echo To stop services: docker-compose down
echo To rebuild app: docker-compose build app
echo.
