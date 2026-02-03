# K3s 설치 및 테스트 환경

이 디렉터리는 로컬 Kubernetes 환경(K3s)을 구축하기 위한 스크립트를 포함합니다.

## 📁 파일 설명

- `install-k3s.sh`: K3s 설치 및 kubectl 설정
- `install-argocd.sh`: Argo CD 설치 (K3s 환경용)

## 🚀 사용 방법

### 1. WSL Ubuntu 접속

```bash
wsl -d Ubuntu-22.04
```

### 2. 스크립트 디렉터리로 이동

```bash
cd /mnt/c/intelliJ/git/pms/infra/k3s
```

### 3. 실행 권한 부여

```bash
chmod +x install-k3s.sh install-argocd.sh
```

### 4. K3s 설치

```bash
sudo bash install-k3s.sh
```

### 5. Argo CD 설치 (선택)

```bash
bash install-argocd.sh
```

## 🔍 설치 확인

### K3s 상태 확인

```bash
kubectl get nodes
kubectl version
```

### Argo CD 접속

```bash
# 포트 포워딩
kubectl port-forward -n argocd svc/argocd-server 8080:443

# 브라우저에서 https://localhost:8080 접속
# Username: admin
# Password: (install-argocd.sh 실행 시 출력됨)
```

## ⚠️ 주의사항

- K3s는 **sudo 권한** 필요
- WSL Ubuntu 22.04 환경 권장
- 최소 2GB RAM, 20GB 디스크 공간 필요

## 🗑️ 제거 방법

### K3s 제거

```bash
sudo /usr/local/bin/k3s-uninstall.sh
```

### Argo CD 제거

```bash
kubectl delete namespace argocd
```
