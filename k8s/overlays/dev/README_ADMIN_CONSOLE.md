# Admin Console Ingress 설정 가이드

**작성일**: 2026-02-06  
**목적**: HTTPS 지원 Admin Console 접속

---

## 🎯 **설정 단계**

### **Step 1: hosts 파일 수정**

#### **Windows (관리자 권한 필요)**:

```powershell
# 관리자 권한으로 PowerShell 실행
Start-Process notepad "C:\Windows\System32\drivers\etc\hosts" -Verb RunAs
```

**추가할 내용**:
```
10.127.6.102    admin.pms.local
```

**전체 예시**:
```
# PMS 개발 환경
10.127.6.102    dev.pms.local
10.127.6.102    admin.pms.local
```

---

### **Step 2: Ingress 적용**

```powershell
kubectl apply -f k8s/overlays/dev/keycloak-admin-ingress.yaml
```

**확인**:
```powershell
kubectl get ingress pms-admin-ingress -n pms-dev
```

---

### **Step 3: 접속 테스트**

#### **HTTP**:
```
http://admin.pms.local/keycloak/admin
```

#### **HTTPS**:
```
https://admin.pms.local/keycloak/admin
```

**로그인**:
```
Username: admin
Password: admin
```

---

## 📊 **접속 방법 정리**

### **Admin Console (master Realm)**:

| 방법 | URL | HTTPS | Cookie Domain | 권장 |
|------|-----|-------|---------------|------|
| **Ingress** | `https://admin.pms.local/keycloak/admin` | ✅ | admin.pms.local | ⭐ |
| **NodePort** | `http://localhost:30880/keycloak/admin` | ❌ | localhost | 임시 |
| **NodePort** | `http://10.127.6.102:30880/keycloak/admin` | ❌ | 10.127.6.102 | 임시 |

### **개발서버 웹 (pms Realm)**:

| URL | Cookie Domain |
|-----|---------------|
| `https://10.127.6.102` | 10.127.6.102 |
| `https://dev.pms.local` (hosts 설정 시) | dev.pms.local |

---

## ✅ **Cookie Domain 분리**

```
개발서버 웹:
  Domain: 10.127.6.102 또는 dev.pms.local
  Realm: pms
  Session: KEYCLOAK_SESSION=pms/...

Admin Console:
  Domain: admin.pms.local ← 분리됨!
  Realm: master
  Session: KEYCLOAK_SESSION=master/...

→ Cookie 충돌 완전 해결!
```

---

## 🚀 **빠른 시작**

### **즉시 사용 (NodePort)**:
```
http://localhost:30880/keycloak/admin
→ admin / admin
```

### **완전한 설정 (Ingress + HTTPS)**:
```
1. hosts 파일에 admin.pms.local 추가
2. kubectl apply -f k8s/overlays/dev/keycloak-admin-ingress.yaml
3. https://admin.pms.local/keycloak/admin 접속
```

---

**작성 완료**: 2026-02-06
