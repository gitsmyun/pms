#!/bin/bash
# Argo CD 설치 스크립트 (K3s 환경)

set -e

echo "========================================="
echo "  Argo CD 설치 시작"
echo "========================================="

# Namespace 생성
kubectl create namespace argocd || true

# Argo CD 설치
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 설치 대기
echo "Argo CD 설치 대기 중..."
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s

# 초기 비밀번호 확인
echo ""
echo "✅ Argo CD 설치 완료!"
echo ""
echo "초기 비밀번호:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
echo ""
echo "접속 방법:"
echo "  kubectl port-forward -n argocd svc/argocd-server 8080:443"
echo "  브라우저에서 https://localhost:8080 접속"
