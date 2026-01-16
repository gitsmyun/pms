# Keycloak 자동 설정 스크립트
# 작성일: 2026-01-16
# 설명: pms realm, pms-frontend client, testuser를 자동으로 생성

param(
    [string]$KeycloakUrl = "http://localhost:8280",
    [string]$AdminUser = "admin",
    [string]$AdminPassword = "admin",
    [string]$DevServerIp = "192.168.1.100"
)

$ErrorActionPreference = "Stop"

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "   Keycloak Auto Setup Script" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

# 1. Admin 토큰 발급
Write-Host "`n[1/5] Admin 토큰 발급 중..." -ForegroundColor Yellow
try {
    $tokenResponse = Invoke-RestMethod -Uri "$KeycloakUrl/realms/master/protocol/openid-connect/token" `
        -Method Post `
        -ContentType "application/x-www-form-urlencoded" `
        -Body @{
            grant_type = "password"
            client_id = "admin-cli"
            username = $AdminUser
            password = $AdminPassword
        }

    $adminToken = $tokenResponse.access_token
    Write-Host "      [OK] Admin token acquired" -ForegroundColor Green
} catch {
    Write-Host "      [FAIL] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "`nPlease check if Keycloak is running: docker ps | Select-String keycloak" -ForegroundColor Yellow
    exit 1
}

# 2. pms Realm 확인 및 생성
Write-Host "`n[2/5] 'pms' Realm 확인 및 생성..." -ForegroundColor Yellow
try {
    $realms = Invoke-RestMethod -Uri "$KeycloakUrl/admin/realms" `
        -Method Get `
        -Headers @{ Authorization = "Bearer $adminToken" }

    $pmsRealm = $realms | Where-Object { $_.realm -eq "pms" }

    if ($pmsRealm) {
        Write-Host "      [INFO] 'pms' Realm already exists." -ForegroundColor Cyan
    } else {
        # Realm creation
        $realmData = @{
            realm = "pms"
            enabled = $true
            displayName = "PMS Application"
            displayNameHtml = "<b>PMS</b> Application"
        } | ConvertTo-Json

        Invoke-RestMethod -Uri "$KeycloakUrl/admin/realms" `
            -Method Post `
            -Headers @{
                Authorization = "Bearer $adminToken"
                "Content-Type" = "application/json"
            } `
            -Body $realmData | Out-Null

        Write-Host "      [OK] 'pms' Realm created" -ForegroundColor Green
    }
} catch {
    Write-Host "      [FAIL] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 3. pms-frontend Client 확인 및 생성
Write-Host "`n[3/5] 'pms-frontend' Client 확인 및 생성..." -ForegroundColor Yellow
try {
    $clients = Invoke-RestMethod -Uri "$KeycloakUrl/admin/realms/pms/clients" `
        -Method Get `
        -Headers @{ Authorization = "Bearer $adminToken" }

    $pmsFrontendClient = $clients | Where-Object { $_.clientId -eq "pms-frontend" }

    if ($pmsFrontendClient) {
        Write-Host "      [INFO] 'pms-frontend' Client already exists." -ForegroundColor Cyan
    } else {
        # Client creation
        $clientData = @{
            clientId = "pms-frontend"
            name = "PMS Frontend Application"
            description = "PMS Frontend Application"
            enabled = $true
            publicClient = $true
            protocol = "openid-connect"
            standardFlowEnabled = $true
            directAccessGrantsEnabled = $true
            implicitFlowEnabled = $false
            serviceAccountsEnabled = $false
            redirectUris = @(
                "http://localhost:5173/*",
                "http://localhost:8181/*",
                "http://${DevServerIp}:8181/*"
            )
            webOrigins = @(
                "http://localhost:5173",
                "http://localhost:8181",
                "http://${DevServerIp}:8181"
            )
            attributes = @{
                "post.logout.redirect.uris" = "http://localhost:5173/*##http://localhost:8181/*##http://${DevServerIp}:8181/*"
            }
        } | ConvertTo-Json -Depth 10

        Invoke-RestMethod -Uri "$KeycloakUrl/admin/realms/pms/clients" `
            -Method Post `
            -Headers @{
                Authorization = "Bearer $adminToken"
                "Content-Type" = "application/json"
            } `
            -Body $clientData | Out-Null

        Write-Host "      [OK] 'pms-frontend' Client created" -ForegroundColor Green
        Write-Host "         - Redirect URIs: localhost:5173, localhost:8181, ${DevServerIp}:8181" -ForegroundColor Gray
    }
} catch {
    Write-Host "      [FAIL] $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host "         Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
    exit 1
}

# 4. testuser 확인 및 생성
Write-Host "`n[4/5] 'testuser' 사용자 확인 및 생성..." -ForegroundColor Yellow
try {
    $users = Invoke-RestMethod -Uri "$KeycloakUrl/admin/realms/pms/users?username=testuser" `
        -Method Get `
        -Headers @{ Authorization = "Bearer $adminToken" }

    if ($users.Count -gt 0) {
        Write-Host "      [INFO] 'testuser' already exists." -ForegroundColor Cyan
        $userId = $users[0].id
    } else {
        # User creation
        $userData = @{
            username = "testuser"
            email = "test@example.com"
            firstName = "Test"
            lastName = "User"
            enabled = $true
            emailVerified = $true
        } | ConvertTo-Json

        Invoke-RestMethod -Uri "$KeycloakUrl/admin/realms/pms/users" `
            -Method Post `
            -Headers @{
                Authorization = "Bearer $adminToken"
                "Content-Type" = "application/json"
            } `
            -Body $userData | Out-Null

        # Get created user ID
        $users = Invoke-RestMethod -Uri "$KeycloakUrl/admin/realms/pms/users?username=testuser" `
            -Method Get `
            -Headers @{ Authorization = "Bearer $adminToken" }
        $userId = $users[0].id

        # Set password
        $passwordData = @{
            type = "password"
            value = "test1234"
            temporary = $false
        } | ConvertTo-Json

        Invoke-RestMethod -Uri "$KeycloakUrl/admin/realms/pms/users/$userId/reset-password" `
            -Method Put `
            -Headers @{
                Authorization = "Bearer $adminToken"
                "Content-Type" = "application/json"
            } `
            -Body $passwordData | Out-Null

        Write-Host "      [OK] 'testuser' created" -ForegroundColor Green
        Write-Host "         - Username: testuser" -ForegroundColor Gray
        Write-Host "         - Password: test1234" -ForegroundColor Gray
        Write-Host "         - Email: test@example.com" -ForegroundColor Gray
    }
} catch {
    Write-Host "      [FAIL] $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host "         Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
    exit 1
}

# 5. 설정 검증 (토큰 발급 테스트)
Write-Host "`n[5/5] 설정 검증 (토큰 발급 테스트)..." -ForegroundColor Yellow
try {
    $testTokenResponse = Invoke-RestMethod -Uri "$KeycloakUrl/realms/pms/protocol/openid-connect/token" `
        -Method Post `
        -ContentType "application/x-www-form-urlencoded" `
        -Body @{
            grant_type = "password"
            client_id = "pms-frontend"
            username = "testuser"
            password = "test1234"
        }

    Write-Host "      [OK] Token issued successfully" -ForegroundColor Green
    Write-Host "         - Token Type: $($testTokenResponse.token_type)" -ForegroundColor Gray
    Write-Host "         - Expires In: $($testTokenResponse.expires_in) seconds" -ForegroundColor Gray
    Write-Host "         - Scope: $($testTokenResponse.scope)" -ForegroundColor Gray
} catch {
    Write-Host "      [FAIL] $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "         Please check Keycloak settings manually." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host "   Keycloak Setup Complete!" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green

Write-Host "`nSetup Summary:" -ForegroundColor Cyan
Write-Host "  - Realm: pms" -ForegroundColor White
Write-Host "  - Client: pms-frontend" -ForegroundColor White
Write-Host "  - Test User: testuser / test1234" -ForegroundColor White
Write-Host "`nKeycloak Admin Console:" -ForegroundColor Cyan
Write-Host "  - URL: $KeycloakUrl" -ForegroundColor White
Write-Host "  - Username: $AdminUser" -ForegroundColor White
Write-Host "  - Password: $AdminPassword" -ForegroundColor White

Write-Host "`nNext Steps:" -ForegroundColor Cyan
Write-Host "  1. Backend SSO Activation:" -ForegroundColor Yellow
Write-Host "     - Edit infra/env/dev.env file" -ForegroundColor White
Write-Host "       OIDC_ISSUER_URI=http://keycloak:8080/realms/pms" -ForegroundColor Gray
Write-Host "     - Restart Backend:" -ForegroundColor White
Write-Host "       cd infra" -ForegroundColor Gray
Write-Host "       docker compose --env-file env\dev.env -f docker-compose.dev.yml up -d --force-recreate backend" -ForegroundColor Gray
Write-Host "`n  2. Frontend SSO Integration (2 hours)" -ForegroundColor Yellow
Write-Host "`n  3. Detailed Guide:" -ForegroundColor Yellow
Write-Host "     docs/ARCH/260116/002_Keycloak_Setup_Step_By_Step.md" -ForegroundColor White

