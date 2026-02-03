# Kubernetes Secret 생성 스크립트 (개발서버용)
# 작성일: 2026-02-03
# 목적: pms-dev namespace에 필수 Secret 생성

$ErrorActionPreference = "Stop"

$NAMESPACE = "pms-dev"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "🔐 Kubernetes Secret 생성 (개발서버)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "1️⃣ Namespace 확인" -ForegroundColor Yellow
Write-Host "----------------------------------------"
try {
    kubectl get namespace $NAMESPACE | Out-Null
    Write-Host "✅ Namespace '$NAMESPACE' 존재함" -ForegroundColor Green
} catch {
    Write-Host "❌ Namespace '$NAMESPACE' 없음! 먼저 생성하세요:" -ForegroundColor Red
    Write-Host "   kubectl create namespace $NAMESPACE" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

Write-Host "2️⃣ PostgreSQL Secret 생성" -ForegroundColor Yellow
Write-Host "----------------------------------------"
kubectl create secret generic postgres-secret `
  --from-literal=password=pms123 `
  -n $NAMESPACE `
  --dry-run=client -o yaml | kubectl apply -f -
Write-Host "✅ postgres-secret 생성 완료" -ForegroundColor Green
Write-Host ""

Write-Host "3️⃣ Keycloak Secret 생성" -ForegroundColor Yellow
Write-Host "----------------------------------------"
kubectl create secret generic keycloak-secret `
  --from-literal=admin-password=admin `
  -n $NAMESPACE `
  --dry-run=client -o yaml | kubectl apply -f -
Write-Host "✅ keycloak-secret 생성 완료" -ForegroundColor Green
Write-Host ""

Write-Host "4️⃣ Secret 목록 확인" -ForegroundColor Yellow
Write-Host "----------------------------------------"
kubectl get secrets -n $NAMESPACE
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Secret 생성 완료!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 생성된 Secret:" -ForegroundColor White
Write-Host "  - postgres-secret (password)" -ForegroundColor White
Write-Host "  - keycloak-secret (admin-password)" -ForegroundColor White
Write-Host ""
Write-Host "🔍 Secret 상세 확인:" -ForegroundColor White
Write-Host "  kubectl describe secret postgres-secret -n $NAMESPACE" -ForegroundColor Gray
Write-Host "  kubectl describe secret keycloak-secret -n $NAMESPACE" -ForegroundColor Gray
Write-Host ""
