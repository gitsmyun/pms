# 빠른 시작 가이드 (Quick Start)

## 🚀 가장 빠른 실행 방법

### 1단계: IntelliJ 터미널 열기
- 단축키: `Alt + F12`
- 또는 하단 **Terminal** 탭 클릭

### 2단계: 명령어 실행
```bash
cd frontend
pnpm dev
```

### 3단계: 브라우저 확인
터미널에 표시된 링크를 **Ctrl + 클릭**:
```
➜  Local:   http://localhost:5173/
```

---

## ✅ 확인 사항

브라우저에서 다음이 보이면 성공:
- ✅ "프로젝트 관리" 제목
- ✅ "새 프로젝트 생성" 폼
- ✅ "프로젝트 목록" 섹션
- ✅ 흰색 카드 스타일 (Tailwind CSS)

---

## 🛑 중지 방법
터미널에서 `Ctrl + C`

---

## 📋 전체 시스템 실행 (Backend 포함)

### 순서:
1. **DB 실행**
   ```bash
   cd infra
   docker compose -f docker-compose.local.yml up -d
   ```

2. **Backend 실행** (IntelliJ)
   - `PmsBackendApplication.java` 실행
   - 확인: http://localhost:8080/swagger-ui.html

3. **Frontend 실행**
   ```bash
   cd frontend
   pnpm dev
   ```
   - 확인: http://localhost:5173

---

## 💡 테스트 시나리오

### ✅ 성공 케이스
1. 프로젝트명: `테스트 프로젝트`
2. 설명: `연동 테스트`
3. "프로젝트 생성" 클릭
4. 목록에 새 프로젝트 표시됨

### ❌ 에러 케이스 (정상 동작 확인)
1. 프로젝트명 비우고 생성 클릭
2. 빨간 에러 박스 표시:
   - `코드: PMS-REQ-400-001`
   - `• name: 프로젝트명은 필수입니다.`

---

더 자세한 내용은 `INTELLIJ_VITE_GUIDE.md` 참고!

