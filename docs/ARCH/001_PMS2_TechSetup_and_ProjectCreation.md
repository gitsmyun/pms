# PMS2.0 기술 세팅 & 프로젝트 생성 가이드  
(Spring Boot 4 + Vue 3 + PostgreSQL + Docker, K8s 친화 설계)

---

## 1. 목표 & 전제

- **목표**
  - PMS2.0을 최신 기술 스택으로 신규 개발
  - 처음부터 **컨테이너 기반, 무상태(Stateless), 설정 외부화**를 전제로 설계
  - 추후 **Kubernetes 도입** 시 애플리케이션 수정 최소화

- **주요 스택**
  - Backend: **Java 21 + Spring Boot 4 + JPA + Security**
  - Frontend: **Vue 3 + Vite + TypeScript + Tailwind CSS v4**
  - DB: **PostgreSQL 18 (Docker 기반)**
  - Infra: **Docker, docker-compose**, (향후 K8s로 확장)
  - IDE: **IntelliJ IDEA Ultimate**
  - 형상관리: **Git**

---

## 2. 기술 버전 정리

| 구분        | 선택 버전 / 도구                      |
|------------|----------------------------------------|
| JDK        | Java 21 (LTS)                          |
| Node.js    | 24 LTS                                 |
| Backend    | Spring Boot 4.x (Gradle – Kotlin DSL)  |
| Frontend   | Vue 3.x + Vite 7.x + TypeScript        |
| CSS        | Tailwind CSS v4 + @tailwindcss/vite    |
| DB         | PostgreSQL 18 (Docker 이미지: postgres:18) |
| 캐시/세션  | Redis 7 (Docker 이미지: redis:7)       |
| 컨테이너   | Docker + docker-compose                |
| IDE        | IntelliJ IDEA Ultimate                 |

> 기존 프로젝트용 **JDK 1.8**은 유지, 새 PMS2.0은 **JDK 21**로 분리 운영  
> → IntelliJ에서 프로젝트별로 SDK를 지정해서 사용

---

## 3. 필수 도구 설치

1. **JDK 21**
   - Temurin 21 등 JDK 설치
   - 기존 JDK 1.8은 삭제하지 않고 그대로 둠

2. **Node.js 24 LTS**
   - 설치 후:
     ```bash
     node -v
     npm -v
     ```

3. **IntelliJ IDEA Ultimate**
   - `File → Project Structure → SDKs` 에
     - JDK 1.8
     - JDK 21  
     두 개 등록

4. **Git**
   - Git for Windows 또는 이미 사용 중인 Git 클라이언트

5. **Docker Desktop**
   - WSL2 기반 설치 권장

---

## 4. 기본 디렉터리 구조

작업 루트 예시:

```text
D:\workspace\PMS2
 ├─ backend      # Spring Boot 4 (Java 21)
 ├─ frontend     # Vue 3 + Vite
 └─ infra        # docker-compose, k8s manifest 등 인프라 정의
```

---

## 5. 로컬 인프라: DB/Redis docker-compose

**파일 위치:** `D:\workspace\PMS2\infra\docker-compose.local.yml`

```yaml
version: "3.9"

services:
  postgres:
    image: postgres:18
    container_name: pms2-postgres
    environment:
      POSTGRES_USER: pms2
      POSTGRES_PASSWORD: pms2_pass
      POSTGRES_DB: pms2
    ports:
      - "5432:5432"
    volumes:
      - ./pg-data:/var/lib/postgresql/data

  redis:
    image: redis:7
    container_name: pms2-redis
    ports:
      - "6379:6379"
```

**기동 명령:**

```bash
cd D:\workspace\PMS2\infra
docker-compose -f docker-compose.local.yml up -d
```

---

## 6. 백엔드 프로젝트 생성 (Spring Boot 4)

### 6.1 IntelliJ에서 Spring 프로젝트 생성

1. **IntelliJ → New Project → Spring Initializr**
2. 설정
   - Project: **Gradle – Kotlin**
   - Language: **Java**
   - Spring Boot: **4.x 최신**
   - Group: `com.company.pms`
   - Artifact: `pms-backend`
   - Name: `pms-backend`
   - Package: `com.company.pms`
   - Java: **21**
3. Dependencies
   - **Spring Web**
   - **Spring Data JPA**
   - **Validation**
   - **Spring Security**
   - **Spring Boot Actuator**
   - **PostgreSQL Driver**
   - **Lombok**

생성 위치: `D:\workspace\PMS2\backend`

---

### 6.2 환경별 설정 구조

`backend/src/main/resources` 에 다음 파일 구성:

- `application.yml` (공통)
- `application-local.yml`
- `application-dev.yml`
- `application-test.yml`
- `application-prod.yml`

**application.yml (공통 설정)**

```yaml
spring:
  profiles:
    default: local

  jpa:
    hibernate:
      ddl-auto: update
    properties:
      hibernate:
        format_sql: true
        show_sql: true
        dialect: org.hibernate.dialect.PostgreSQLDialect

server:
  port: 8080

management:
  endpoints:
    web:
      exposure:
        include: health,info
```

**application-local.yml (로컬용, Docker DB/Redis 사용)**

```yaml
spring:
  datasource:
    url: jdbc:postgresql://${POSTGRES_HOST:localhost}:${POSTGRES_PORT:5432}/pms2
    username: ${POSTGRES_USER:pms2}
    password: ${POSTGRES_PASSWORD:pms2_pass}
    driver-class-name: org.postgresql.Driver

  redis:
    host: ${REDIS_HOST:localhost}
    port: ${REDIS_PORT:6379}
```

> DB/Redis 정보는 **환경변수 기반**으로 설정  
> → 나중에 Dev/Test/Prod, K8s로 확장할 때 ConfigMap/Secret으로 대체 가능

---

### 6.3 헬스 체크 컨트롤러

`backend/src/main/java/com/company/pms/api/HealthController.java`:

```java
package com.company.pms.api;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class HealthController {

    @GetMapping("/api/health")
    public Map<String, Object> health() {
        return Map.of(
                "status", "OK",
                "app", "PMS2-backend",
                "env", System.getenv().getOrDefault("SPRING_PROFILES_ACTIVE", "local")
        );
    }
}
```

**실행 테스트:**

- IntelliJ에서 `PmsBackendApplication` Run
- 브라우저에서:  
  `http://localhost:8080/api/health` → JSON 응답 확인

---

### 6.4 백엔드 Dockerfile (멀티스테이지)

**파일 위치:** `D:\workspace\PMS2\backend\Dockerfile`

```dockerfile
# Build stage
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app
COPY ../../../../../../Users/USER/Downloads .
RUN ./gradlew clean bootJar --no-daemon

# Run stage
FROM eclipse-temurin:21-jre
WORKDIR /app

# 프로필은 환경변수로 제어 (K8s/Dev/Test/Prod 공통)
ENV SPRING_PROFILES_ACTIVE=prod

COPY --from=build /app/build/libs/*.jar app.jar
EXPOSE 8080

ENTRYPOINT ["java","-jar","/app/app.jar"]
```

> 이 이미지는 **로컬/Dev/Test/Prod/K8s에서 모두 동일하게 사용 가능**  
> → 환경별로 `SPRING_PROFILES_ACTIVE`와 DB/Redis ENV만 다르게 전달

---

## 7. 프론트엔드 프로젝트 생성 (Vue 3 + Vite + TS)

### 7.1 Vite + Vue + TS 스캐폴딩

```bash
cd D:\workspace\PMS2
npm create vite@latest frontend
# Framework: Vue
# Variant: TypeScript

cd frontend
npm install
npm run dev
```

브라우저: `http://localhost:5173` 정상 출력 확인

---

### 7.2 Tailwind CSS v4 + Vite 플러그인 설정

```bash
cd frontend
npm install -D tailwindcss @tailwindcss/vite
```

**vite.config.ts**

```ts
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  plugins: [
    vue(),
    tailwindcss(),
  ],
  server: {
    port: 5173,
    proxy: {
      '/api': {
        target: 'http://localhost:8080',
        changeOrigin: true,
      },
    },
  },
})
```

**src/style.css**

```css
@import "tailwindcss";
```

**src/main.ts**

```ts
import { createApp } from 'vue'
import App from './App.vue'
import './style.css'

createApp(App).mount('#app')
```

---

### 7.3 API Base URL 환경변수 (환경별 분리 대비)

루트에 `.env.local` 생성:

```env
VITE_API_BASE_URL=http://localhost:8080
```

**src/api/http.ts** (예시):

```ts
const baseUrl = import.meta.env.VITE_API_BASE_URL || '/api'

export async function getHealth() {
  const res = await fetch(`${baseUrl}/api/health`)
  return await res.json()
}
```

> Prod/Test 환경에서는 `.env.prod`, `.env.test` 등에 다른 URL을 지정

---

### 7.4 App.vue에서 백엔드 헬스 체크 호출

**src/App.vue**

```vue
<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { getHealth } from './api/http'

const health = ref<any>(null)

onMounted(async () => {
  health.value = await getHealth()
})
</script>

<template>
  <main class="min-h-screen bg-slate-50 flex items-center justify-center">
    <div class="bg-white shadow-lg rounded-2xl p-8 space-y-4">
      <h1 class="text-2xl font-bold text-slate-800">
        PMS2 (Spring Boot 4 + Vue 3 + PostgreSQL)
      </h1>
      <pre class="text-sm text-slate-700 bg-slate-100 rounded-lg p-4">
{{ health }}
      </pre>
    </div>
  </main>
</template>
```

---

### 7.5 프론트 Dockerfile

**파일 위치:** `D:\workspace\PMS2\frontend\Dockerfile`

```dockerfile
# Build stage
FROM node:24 AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Run stage (Nginx)
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
```

---

## 8. 로컬 통합 실행용 docker-compose (앱까지 포함)

**파일 위치:** `D:\workspace\PMS2\infra\docker-compose.app.local.yml`

```yaml
version: "3.9"

services:
  postgres:
    image: postgres:18
    container_name: pms2-postgres
    environment:
      POSTGRES_USER: pms2
      POSTGRES_PASSWORD: pms2_pass
      POSTGRES_DB: pms2
    ports:
      - "5432:5432"
    volumes:
      - ./pg-data:/var/lib/postgresql/data

  redis:
    image: redis:7
    container_name: pms2-redis
    ports:
      - "6379:6379"

  backend:
    build: ../backend
    environment:
      SPRING_PROFILES_ACTIVE: local
      POSTGRES_HOST: postgres
      POSTGRES_PORT: 5432
      POSTGRES_USER: pms2
      POSTGRES_PASSWORD: pms2_pass
      REDIS_HOST: redis
      REDIS_PORT: 6379
    depends_on:
      - postgres
      - redis
    ports:
      - "8080:8080"

  frontend:
    build: ../frontend
    depends_on:
      - backend
    ports:
      - "5173:80"
```

**실행:**

```bash
cd D:\workspace\PMS2\infra
docker-compose -f docker-compose.app.local.yml up -d --build
```

**접속:**

- 프론트: `http://localhost:5173`
- 프론트 화면에서 `getHealth()` 호출 → 백엔드 `/api/health` 응답 확인

---

## 9. 여기까지 진행 후 다음 단계

이 문서 기준으로 진행 범위:

1. 도구 설치 (JDK 21, Node 24, IntelliJ, Docker)
2. 폴더 구조 생성 (`PMS2/backend`, `frontend`, `infra`)
3. DB/Redis용 docker-compose.local 실행
4. Spring Boot 4 백엔드 생성 + 설정 + Dockerfile 작성
5. Vue 3 + Vite 프론트 생성 + Tailwind + API 호출 + Dockerfile 작성
6. 통합 docker-compose.app.local로 백엔드·프론트까지 함께 기동

→ 여기까지 완료되면, 로컬에서 컨테이너 기반 PMS2.0 골격이 동작하는 상태가 되며  
   이후 Dev/Test/Prod 및 Kubernetes 확장 시 애플리케이션 수정은 최소화할 수 있다.
