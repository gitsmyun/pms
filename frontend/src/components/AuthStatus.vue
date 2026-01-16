<!--
  로그인 상태 표시 및 로그인/로그아웃 버튼

  SSO (Keycloak) 인증 상태를 표시하고 로그인/로그아웃 기능 제공

  @author 윤성민 책임
  @since 2026-01-15
-->
<template>
  <div class="auth-status">
    <div v-if="isAuthenticated" class="user-info">
      <span class="welcome-message">환영합니다, {{ username }}님</span>
      <button @click="handleLogout" class="btn btn-logout">로그아웃</button>
    </div>
    <div v-else class="login-prompt">
      <span>로그인이 필요합니다</span>
      <button @click="handleLogin" class="btn btn-login">로그인</button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import keycloak from '@/keycloak'
import { login, logout, getCurrentUser } from '@/utils/auth'

const isAuthenticated = ref(false)
const username = ref('')

onMounted(() => {
  // Keycloak 인증 상태 확인
  isAuthenticated.value = keycloak.authenticated || false

  if (isAuthenticated.value) {
    const user = getCurrentUser()
    username.value = user?.username || ''
  }
})

function handleLogin() {
  login()
}

function handleLogout() {
  logout()
}
</script>

<style scoped>
.auth-status {
  padding: 1rem 2rem;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  display: flex;
  justify-content: flex-end;
  align-items: center;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
}

.user-info,
.login-prompt {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.welcome-message {
  font-weight: 500;
}

.btn {
  padding: 0.5rem 1.5rem;
  border: none;
  border-radius: 4px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-login {
  background: white;
  color: #667eea;
}

.btn-login:hover {
  background: #f7f7f7;
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.15);
}

.btn-logout {
  background: rgba(255, 255, 255, 0.2);
  color: white;
  border: 1px solid white;
}

.btn-logout:hover {
  background: rgba(255, 255, 255, 0.3);
  transform: translateY(-1px);
}
</style>

