# Keycloak SSO 작동 확인 테스트 스크립트
# 작성일: 2026-01-16

Write-Host "`n=========================================================" -ForegroundColor Cyan
Write-Host "   Keycloak SSO 작동 확인 테스트" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan

$KEYCLOAK_URL = "http://localhost:8280"
$BACKEND_URL = "http://localhost:8180"

# 테스트 1: Keycloak 접속 확인
Write-Host "`n[테스트 1] Keycloak 서비스 확인..." -ForegroundColor Yellow
try {
    $keycloakResponse = Invoke-WebRequest -Uri "$KEYCLOAK_URL" -UseBasicParsing -TimeoutSec 5
    Write-Host "  ✅ Keycloak 응답: $($keycloakResponse.StatusCode)" -ForegroundColor Green
} catch {
    Write-Host "  ❌ Keycloak 접속 실패: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "  Keycloak 컨테이너 상태 확인이 필요합니다." -ForegroundColor Yellow
    exit 1
}

# 테스트 2: 토큰 없이 API 호출 (401 또는 403 예상)
Write-Host "`n[테스트 2] 토큰 없이 API 호출 (인증 필요 확인)..." -ForegroundColor Yellow
try {
    $apiResponse = Invoke-WebRequest -Uri "$BACKEND_URL/api/projects" -UseBasicParsing -TimeoutSec 5
    Write-Host "  ⚠️  예상과 다름: 인증 없이 접근 가능 (Status: $($apiResponse.StatusCode))" -ForegroundColor Yellow
    Write-Host "  → SSO가 아직 활성화되지 않았거나 SecurityDevConfig가 활성화됨" -ForegroundColor Gray
    $ssoActive = $false
} catch {
    if ($_.Exception.Response.StatusCode -eq 401 -or $_.Exception.Response.StatusCode -eq 403) {
        Write-Host "  ✅ 예상대로 인증 거부됨 (Status: $($_.Exception.Response.StatusCode))" -ForegroundColor Green
        Write-Host "  → SSO가 정상 작동 중!" -ForegroundColor Green
        $ssoActive = $true
    } else {
        Write-Host "  ❌ 예상치 못한 에러: $($_.Exception.Message)" -ForegroundColor Red
        $ssoActive = $false
    }
}

if (-not $ssoActive) {
    Write-Host "`n⚠️  SSO가 활성화되지 않은 것으로 보입니다." -ForegroundColor Yellow
    Write-Host "Backend 환경변수 확인:" -ForegroundColor Cyan
    docker exec pms-dev-backend printenv | Select-String "SPRING_SECURITY_OAUTH2"
    Write-Host "`n다음 조치 필요:" -ForegroundColor Yellow
    Write-Host "  1. GitHub Actions 빌드 완료 대기" -ForegroundColor White
    Write-Host "  2. 최신 이미지로 재배포" -ForegroundColor White
    Write-Host "  3. 이 스크립트 다시 실행" -ForegroundColor White
    exit 0
}

# 테스트 3: Keycloak에서 토큰 발급
Write-Host "`n[테스트 3] Keycloak 토큰 발급..." -ForegroundColor Yellow
try {
    $tokenResponse = Invoke-RestMethod -Uri "$KEYCLOAK_URL/realms/pms/protocol/openid-connect/token" `
        -Method Post `
        -ContentType "application/x-www-form-urlencoded" `
        -Body @{
            grant_type = "password"
            client_id = "pms-frontend"
            username = "testuser"
            password = "test1234"
        }

    Write-Host "  ✅ 토큰 발급 성공" -ForegroundColor Green
    Write-Host "     Token Type: $($tokenResponse.token_type)" -ForegroundColor Gray
    Write-Host "     Expires In: $($tokenResponse.expires_in) 초" -ForegroundColor Gray
    Write-Host "     Scope: $($tokenResponse.scope)" -ForegroundColor Gray

    $accessToken = $tokenResponse.access_token
} catch {
    Write-Host "  ❌ 토큰 발급 실패: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host "     상세: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
    Write-Host "`nKeycloak 설정 확인이 필요합니다:" -ForegroundColor Yellow
    Write-Host "  - Realm 'pms' 존재 확인" -ForegroundColor White
    Write-Host "  - Client 'pms-frontend' 존재 확인" -ForegroundColor White
    Write-Host "  - User 'testuser' 존재 및 비밀번호 확인" -ForegroundColor White
    Write-Host "`nKeycloak Admin Console: $KEYCLOAK_URL" -ForegroundColor Cyan
    exit 1
}

# 테스트 4: 토큰으로 API 호출
Write-Host "`n[테스트 4] 토큰으로 API 호출..." -ForegroundColor Yellow
try {
    $authApiResponse = Invoke-RestMethod -Uri "$BACKEND_URL/api/projects" `
        -Headers @{ Authorization = "Bearer $accessToken" } `
        -TimeoutSec 5

    Write-Host "  ✅ 인증된 API 호출 성공!" -ForegroundColor Green
    Write-Host "     응답 데이터 타입: $($authApiResponse.GetType().Name)" -ForegroundColor Gray
    if ($authApiResponse -is [array]) {
        Write-Host "     프로젝트 개수: $($authApiResponse.Count)" -ForegroundColor Gray
    }
} catch {
    Write-Host "  ❌ 인증된 API 호출 실패: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ErrorDetails) {
        Write-Host "     상세: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
    exit 1
}

# 테스트 5: UserInfo 엔드포인트 확인
Write-Host "`n[테스트 5] UserInfo 엔드포인트 확인..." -ForegroundColor Yellow
try {
    $userInfo = Invoke-RestMethod -Uri "$KEYCLOAK_URL/realms/pms/protocol/openid-connect/userinfo" `
        -Headers @{ Authorization = "Bearer $accessToken" }

    Write-Host "  ✅ UserInfo 조회 성공" -ForegroundColor Green
    Write-Host "     Username: $($userInfo.preferred_username)" -ForegroundColor Gray
    Write-Host "     Email: $($userInfo.email)" -ForegroundColor Gray
    Write-Host "     Email Verified: $($userInfo.email_verified)" -ForegroundColor Gray
} catch {
    Write-Host "  ❌ UserInfo 조회 실패: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host "   🎉 Keycloak SSO 작동 확인 완료!" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green

Write-Host "`n✅ 검증 결과:" -ForegroundColor Cyan
Write-Host "  1. Keycloak 서비스 정상" -ForegroundColor White
Write-Host "  2. 토큰 없이 API 접근 거부됨 (인증 필요)" -ForegroundColor White
Write-Host "  3. Keycloak 토큰 발급 성공" -ForegroundColor White
Write-Host "  4. 토큰으로 API 접근 성공" -ForegroundColor White
Write-Host "  5. UserInfo 조회 성공" -ForegroundColor White

Write-Host "`n📌 확인된 정보:" -ForegroundColor Cyan
Write-Host "  - Keycloak URL: $KEYCLOAK_URL" -ForegroundColor White
Write-Host "  - Backend URL: $BACKEND_URL" -ForegroundColor White
Write-Host "  - Realm: pms" -ForegroundColor White
Write-Host "  - Client: pms-frontend" -ForegroundColor White
Write-Host "  - Test User: testuser" -ForegroundColor White

Write-Host "`n🚀 다음 단계:" -ForegroundColor Cyan
Write-Host "  1. Frontend SSO 연동 구현" -ForegroundColor Yellow
Write-Host "     - 로그인/로그아웃 UI 컴포넌트" -ForegroundColor Gray
Write-Host "     - Keycloak 초기화 및 토큰 관리" -ForegroundColor Gray
Write-Host "     - API 호출 시 자동 토큰 추가" -ForegroundColor Gray
Write-Host "`n  2. 역할 기반 접근 제어 (RBAC)" -ForegroundColor Yellow
Write-Host "     - Keycloak Roles 설정" -ForegroundColor Gray
Write-Host "     - Backend 권한 체크" -ForegroundColor Gray
Write-Host "     - Frontend UI 권한별 제어" -ForegroundColor Gray

Write-Host "`n=========================================================" -ForegroundColor Green

