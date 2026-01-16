# Frontend 개발 서버 배포 스크립트
# GitHub Actions 빌드 완료 후 실행

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host "   Frontend 개발 서버 배포" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green

$infraPath = "C:\intelliJ\git\pms\infra"

Write-Host "`n[1/4] 최신 Frontend 이미지 Pull..." -ForegroundColor Yellow
Set-Location $infraPath
docker compose --env-file env\dev.env -f docker-compose.dev.yml pull frontend

Write-Host "`n[2/4] Frontend 컨테이너 재시작..." -ForegroundColor Yellow
docker compose --env-file env\dev.env -f docker-compose.dev.yml up -d --force-recreate frontend

Write-Host "`n[3/4] 시작 대기 (10초)..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "`n[4/4] 컨테이너 상태 확인..." -ForegroundColor Yellow
docker ps --filter "name=pms-dev-frontend" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

Write-Host "`n=========================================================" -ForegroundColor Green
Write-Host "   배포 완료!" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green

Write-Host "`n🌐 개발 서버 접속:" -ForegroundColor Cyan
Write-Host "  http://localhost:8181" -ForegroundColor Blue

Write-Host "`n🔐 테스트 계정:" -ForegroundColor Yellow
Write-Host "  Username: testuser" -ForegroundColor White
Write-Host "  Password: test1234" -ForegroundColor White

Write-Host "`n💡 참고:" -ForegroundColor Gray
Write-Host "  - 로그인 버튼 클릭 → Keycloak 로그인 페이지" -ForegroundColor White
Write-Host "  - 로그인 성공 → 사용자 프로필 표시" -ForegroundColor White
Write-Host "  - API 호출 시 자동으로 토큰 추가됨" -ForegroundColor White

Write-Host "`n=========================================================" -ForegroundColor Green

