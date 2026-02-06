#!/bin/bash
# Kubernetes Secret 생성 스크립트 (개발서버용)
# 작성일: 2026-02-03
# 목적: pms-dev namespace에 필수 Secret 생성

set -e

NAMESPACE="pms-dev"

echo "========================================"
echo "🔐 Kubernetes Secret 생성 (개발서버)"
echo "========================================"
echo ""

echo "1️⃣ Namespace 확인"
echo "----------------------------------------"
if kubectl get namespace $NAMESPACE > /dev/null 2>&1; then
  echo "✅ Namespace '$NAMESPACE' 존재함"
else
  echo "❌ Namespace '$NAMESPACE' 없음! 먼저 생성하세요:"
  echo "   kubectl create namespace $NAMESPACE"
  exit 1
fi
echo ""

# 2. PostgreSQL Secret 생성
echo "----------------------------------------"
kubectl create secret generic postgres-secret \
  --from-literal=password=test123 \
  -n $NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -
echo "✅ postgres-secret 생성 완료"
echo ""

echo "3️⃣ Keycloak Secret 생성"
echo "----------------------------------------"
kubectl create secret generic keycloak-secret \
  --from-literal=admin-password=admin \
  -n $NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -
echo "✅ keycloak-secret 생성 완료"
echo ""

echo "4️⃣ Secret 목록 확인"
echo "----------------------------------------"
kubectl get secrets -n $NAMESPACE
echo ""

echo "========================================"
echo "✅ Secret 생성 완료!"
echo "========================================"
echo ""
echo "📋 생성된 Secret:"
echo "  - postgres-secret (password)"
echo "  - keycloak-secret (admin-password)"
echo ""
echo "🔍 Secret 상세 확인:"
echo "  kubectl describe secret postgres-secret -n $NAMESPACE"
echo "  kubectl describe secret keycloak-secret -n $NAMESPACE"
echo ""
