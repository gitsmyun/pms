#!/bin/bash
# K3s 설치 스크립트 (WSL Ubuntu 또는 Linux)

set -e

echo "========================================="
echo "  K3s 설치 시작"
echo "========================================="
echo ""

# K3s 설치
echo "📥 K3s 다운로드 및 설치 중..."
curl -sfL https://get.k3s.io | sh -

echo ""
echo "⏳ K3s 서비스 시작 대기 중 (최대 60초)..."
echo ""

# K3s 서비스 시작 대기
sleep 5

# K3s API 서버 준비 대기 (최대 60초)
TIMEOUT=60
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    if sudo k3s kubectl get nodes >/dev/null 2>&1; then
        echo "✅ K3s API 서버 준비 완료!"
        break
    fi
    echo "   대기 중... ($ELAPSED/${TIMEOUT}초)"
    sleep 5
    ELAPSED=$((ELAPSED + 5))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
    echo "❌ K3s 서비스 시작 시간 초과"
    echo ""
    echo "디버깅 정보:"
    sudo systemctl status k3s || true
    exit 1
fi

# kubectl 설정
echo ""
echo "🔧 kubectl 설정 중..."
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config

# KUBECONFIG 환경변수 설정
export KUBECONFIG=~/.kube/config

# 설치 확인
echo ""
echo "========================================="
echo "  ✅ K3s 설치 완료!"
echo "========================================="
echo ""

echo "📊 클러스터 상태:"
kubectl get nodes

echo ""
echo "🔍 K3s 버전:"
kubectl version --short 2>/dev/null || kubectl version

echo ""
echo "========================================="
echo "  다음 단계"
echo "========================================="
echo ""
echo "1. kubectl 명령어 사용 가능:"
echo "   kubectl get nodes"
echo "   kubectl get pods --all-namespaces"
echo ""
echo "2. KUBECONFIG 환경변수 설정 (새 터미널 세션에서):"
echo "   export KUBECONFIG=~/.kube/config"
echo ""
echo "3. 또는 .bashrc에 추가 (영구 설정):"
echo "   echo 'export KUBECONFIG=~/.kube/config' >> ~/.bashrc"
echo "   source ~/.bashrc"
echo ""
