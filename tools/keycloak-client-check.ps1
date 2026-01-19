# Keycloak 클라이언트 설정 확인 및 수정 스크립트
#
# 작성일: 2026-01-19
# 작성자: AI Assistant (윤성민 책임 요청)
# 설명: Keycloak 클라이언트 설정을 확인하고 필요시 수정

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "Keycloak 클라이언트 설정 확인" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

# 설정 변수
$KEYCLOAK_URL = "http://localhost:8280"
$REALM = "pms"
$CLIENT_ID = "pms-frontend"
$ADMIN_USER = "admin"
$ADMIN_PASSWORD = "admin"

Write-Host "📋 설정 정보:" -ForegroundColor Yellow
Write-Host "  - Keycloak URL: $KEYCLOAK_URL"
Write-Host "  - Realm: $REALM"
Write-Host "  - Client ID: $CLIENT_ID"
Write-Host ""

# 1. Keycloak 서버 상태 확인
Write-Host "1️⃣  Keycloak 서버 상태 확인..." -ForegroundColor Green
try {
    $response = Invoke-WebRequest -Uri "$KEYCLOAK_URL/health/ready" -Method GET -UseBasicParsing -TimeoutSec 5
    Write-Host "  ✅ Keycloak 서버 응답: $($response.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Keycloak 서버 응답 없음" -ForegroundColor Red
    Write-Host "  💡 Docker 컨테이너를 확인하세요: docker compose -f infra/docker-compose.dev.yml ps" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# 2. Admin 토큰 획득
Write-Host "2️⃣  Admin 토큰 획득 중..." -ForegroundColor Green
try {
    $tokenResponse = Invoke-RestMethod -Uri "$KEYCLOAK_URL/realms/master/protocol/openid-connect/token" `
        -Method POST `
        -ContentType "application/x-www-form-urlencoded" `
        -Body @{
            username = $ADMIN_USER
            password = $ADMIN_PASSWORD
            grant_type = "password"
            client_id = "admin-cli"
        }

    $accessToken = $tokenResponse.access_token
    Write-Host "  ✅ 토큰 획득 성공" -ForegroundColor Green
} catch {
    Write-Host "  ❌ 토큰 획득 실패: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  💡 admin 계정 정보를 확인하세요" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# 3. 클라이언트 정보 조회
Write-Host "3️⃣  클라이언트 정보 조회 중..." -ForegroundColor Green
try {
    $headers = @{
        "Authorization" = "Bearer $accessToken"
        "Content-Type" = "application/json"
    }

    # 모든 클라이언트 조회
    $clients = Invoke-RestMethod -Uri "$KEYCLOAK_URL/admin/realms/$REALM/clients" `
        -Method GET `
        -Headers $headers

    # pms-frontend 클라이언트 찾기
    $client = $clients | Where-Object { $_.clientId -eq $CLIENT_ID }

    if ($null -eq $client) {
        Write-Host "  ❌ 클라이언트 '$CLIENT_ID'를 찾을 수 없습니다" -ForegroundColor Red
        Write-Host "  💡 Keycloak Admin Console에서 클라이언트를 생성하세요" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "  ✅ 클라이언트 발견: $($client.clientId)" -ForegroundColor Green
    Write-Host ""

    # 4. 현재 설정 출력
    Write-Host "4️⃣  현재 클라이언트 설정:" -ForegroundColor Green
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host "  📌 기본 설정" -ForegroundColor Cyan
    Write-Host "    - Client ID: $($client.clientId)"
    Write-Host "    - Enabled: $($client.enabled)"
    Write-Host "    - Protocol: $($client.protocol)"
    Write-Host "    - Public Client: $($client.publicClient)"
    Write-Host ""

    Write-Host "  📌 OAuth Flow" -ForegroundColor Cyan
    Write-Host "    - Standard Flow: $($client.standardFlowEnabled)"
    Write-Host "    - Direct Access Grants: $($client.directAccessGrantsEnabled)"
    Write-Host "    - Implicit Flow: $($client.implicitFlowEnabled)"
    Write-Host ""

    Write-Host "  📌 Redirect URIs" -ForegroundColor Cyan
    if ($client.redirectUris -and $client.redirectUris.Count -gt 0) {
        foreach ($uri in $client.redirectUris) {
            $color = if ($uri -match "10\.127\.6\.102") { "Yellow" } else { "White" }
            Write-Host "    - $uri" -ForegroundColor $color
        }
    } else {
        Write-Host "    ⚠️  설정된 Redirect URI가 없습니다" -ForegroundColor Yellow
    }
    Write-Host ""

    Write-Host "  📌 Web Origins" -ForegroundColor Cyan
    if ($client.webOrigins -and $client.webOrigins.Count -gt 0) {
        foreach ($origin in $client.webOrigins) {
            $color = if ($origin -match "10\.127\.6\.102") { "Yellow" } else { "White" }
            Write-Host "    - $origin" -ForegroundColor $color
        }
    } else {
        Write-Host "    ⚠️  설정된 Web Origin이 없습니다" -ForegroundColor Yellow
    }
    Write-Host ""

    Write-Host "  📌 PKCE 설정" -ForegroundColor Cyan
    $pkceMethod = if ($client.attributes -and $client.attributes."pkce.code.challenge.method") {
        $client.attributes."pkce.code.challenge.method"
    } else {
        "(설정 안 됨)"
    }
    Write-Host "    - PKCE Code Challenge Method: $pkceMethod"
    Write-Host ""

    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host ""

    # 5. 설정 검증
    Write-Host "5️⃣  설정 검증:" -ForegroundColor Green
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

    $hasIssues = $false

    # Redirect URI 검증
    $requiredRedirects = @(
        "http://localhost:8181/*",
        "http://10.127.6.102:8181/*"
    )

    Write-Host "  📋 Redirect URI 검증:" -ForegroundColor Cyan
    foreach ($required in $requiredRedirects) {
        $exists = $client.redirectUris -contains $required
        if ($exists) {
            Write-Host "    ✅ $required" -ForegroundColor Green
        } else {
            Write-Host "    ❌ $required (누락)" -ForegroundColor Red
            $hasIssues = $true
        }
    }
    Write-Host ""

    # Web Origins 검증
    $requiredOrigins = @(
        "http://localhost:8181",
        "http://10.127.6.102:8181"
    )

    Write-Host "  📋 Web Origins 검증:" -ForegroundColor Cyan
    foreach ($required in $requiredOrigins) {
        $exists = $client.webOrigins -contains $required
        if ($exists) {
            Write-Host "    ✅ $required" -ForegroundColor Green
        } else {
            Write-Host "    ❌ $required (누락)" -ForegroundColor Red
            $hasIssues = $true
        }
    }
    Write-Host ""

    # PKCE 검증
    Write-Host "  📋 PKCE 검증:" -ForegroundColor Cyan
    if ($pkceMethod -eq "S256") {
        Write-Host "    ✅ PKCE S256 활성화" -ForegroundColor Green
        Write-Host "    ⚠️  주의: HTTP + IP 접속 시 Web Crypto API 오류 발생" -ForegroundColor Yellow
    } elseif ($pkceMethod -eq "" -or $pkceMethod -eq "(설정 안 됨)") {
        Write-Host "    ⚠️  PKCE 비활성화 (보안 취약)" -ForegroundColor Yellow
        Write-Host "    💡 권장: PKCE S256 활성화 + HTTPS 사용" -ForegroundColor Yellow
    } else {
        Write-Host "    ℹ️  PKCE Method: $pkceMethod" -ForegroundColor White
    }
    Write-Host ""

    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
    Write-Host ""

    # 6. 권장 사항
    Write-Host "6️⃣  권장 사항:" -ForegroundColor Green
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

    if ($hasIssues) {
        Write-Host "  ⚠️  설정 문제가 발견되었습니다" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  📝 수정 방법:" -ForegroundColor Cyan
        Write-Host "    1. Keycloak Admin Console 접속: $KEYCLOAK_URL/admin" -ForegroundColor White
        Write-Host "    2. Realm: $REALM 선택" -ForegroundColor White
        Write-Host "    3. Clients > $CLIENT_ID 선택" -ForegroundColor White
        Write-Host "    4. Settings 탭에서 아래 항목 수정:" -ForegroundColor White
        Write-Host ""
        Write-Host "       Valid Redirect URIs:" -ForegroundColor Yellow
        Write-Host "         - http://localhost:8181/*" -ForegroundColor White
        Write-Host "         - http://10.127.6.102:8181/*" -ForegroundColor White
        Write-Host ""
        Write-Host "       Web Origins:" -ForegroundColor Yellow
        Write-Host "         - http://localhost:8181" -ForegroundColor White
        Write-Host "         - http://10.127.6.102:8181" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "  ✅ 기본 설정이 정상입니다" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "  💡 추가 권장 사항:" -ForegroundColor Cyan
    Write-Host "    • HTTPS 적용 (Web Crypto API 오류 해결)" -ForegroundColor White
    Write-Host "      → 자체 서명 인증서: docs/ARCH/260119/001_Keycloak_URL_Debug_and_WebCrypto_Fix.md 참조" -ForegroundColor Gray
    Write-Host ""
    Write-Host "    • PKCE S256 활성화 (OAuth 2.1 표준)" -ForegroundColor White
    Write-Host "      → Advanced Settings > Proof Key for Code Exchange Code Challenge Method: S256" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray

} catch {
    Write-Host "  ❌ 클라이언트 정보 조회 실패: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "완료" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan
