<template>
  <!-- 사용자 메뉴 (제미나이 스타일) -->
  <div class="user-menu" v-if="isAuthenticated" :class="{ 'open': isDropdownOpen }">
    <!-- 사용자 메뉴 트리거 -->
    <div class="user-menu-trigger" @click="toggleDropdown">
      <div class="user-avatar" style="background: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);">
        <svg width="20" height="20" viewBox="0 0 20 20" fill="white">
          <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd"/>
        </svg>
      </div>
      <div class="user-info">
        <div class="user-name">{{ username }}</div>
        <div class="user-role">{{ role }}</div>
      </div>
      <span class="user-menu-arrow">
        <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd"/>
        </svg>
      </span>
    </div>

    <!-- 드롭다운 메뉴 -->
    <div class="user-dropdown">
      <div class="user-dropdown-header">
        <div class="user-dropdown-name">{{ fullName }}</div>
        <div class="user-dropdown-email">{{ email }}</div>
      </div>
      <div class="user-dropdown-menu">
        <a class="user-dropdown-item" @click="goToProfile">
          <span class="user-dropdown-icon">
            <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd"/>
            </svg>
          </span>
          <span>프로필</span>
        </a>
        <a class="user-dropdown-item" @click="goToSettings">
          <span class="user-dropdown-icon">
            <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M11.49 3.17c-.38-1.56-2.6-1.56-2.98 0a1.532 1.532 0 01-2.286.948c-1.372-.836-2.942.734-2.106 2.106.54.886.061 2.042-.947 2.287-1.561.379-1.561 2.6 0 2.978a1.532 1.532 0 01.947 2.287c-.836 1.372.734 2.942 2.106 2.106a1.532 1.532 0 012.287.947c.379 1.561 2.6 1.561 2.978 0a1.533 1.533 0 012.287-.947c1.372.836 2.942-.734 2.106-2.106a1.533 1.533 0 01.947-2.287c1.561-.379 1.561-2.6 0-2.978a1.532 1.532 0 01-.947-2.287c.836-1.372-.734-2.942-2.106-2.106a1.532 1.532 0 01-2.287-.947zM10 13a3 3 0 100-6 3 3 0 000 6z" clip-rule="evenodd"/>
            </svg>
          </span>
          <span>설정</span>
        </a>
        <div class="user-dropdown-divider"></div>
        <a class="user-dropdown-item danger" @click="logout">
          <span class="user-dropdown-icon">
            <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M3 3a1 1 0 00-1 1v12a1 1 0 102 0V4a1 1 0 00-1-1zm10.293 9.293a1 1 0 001.414 1.414l3-3a1 1 0 000-1.414l-3-3a1 1 0 10-1.414 1.414L14.586 9H7a1 1 0 100 2h7.586l-1.293 1.293z" clip-rule="evenodd"/>
            </svg>
          </span>
          <span>로그아웃</span>
        </a>
      </div>
    </div>
  </div>

  <!-- 로그인 버튼 (미인증 시) -->
  <button
    v-else
    @click="login"
    class="btn btn-primary"
  >
    <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
      <path fill-rule="evenodd" d="M3 3a1 1 0 011 1v12a1 1 0 11-2 0V4a1 1 0 011-1zm7.707 3.293a1 1 0 010 1.414L9.414 9H17a1 1 0 110 2H9.414l1.293 1.293a1 1 0 01-1.414 1.414l-3-3a1 1 0 010-1.414l3-3a1 1 0 011.414 0z" clip-rule="evenodd"/>
    </svg>
    로그인
  </button>
</template>

<script setup lang="ts">
/**
 * 사용자 프로필 컴포넌트
 *
 * 제미나이 스타일 사용자 메뉴 (공통 CSS 활용)
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 * @updated 2026-02-11 - 제미나이 스타일 user-menu 적용
 */
import { ref, computed, inject, onMounted, onUnmounted } from 'vue'
import type Keycloak from 'keycloak-js'

// Keycloak 인스턴스 주입
const keycloak = inject<Keycloak>('keycloak')

// 상태
const isDropdownOpen = ref(false)

// 계산된 속성
const isAuthenticated = computed(() => keycloak?.authenticated || false)
const username = computed(() => keycloak?.tokenParsed?.preferred_username || 'User')
const fullName = computed(() => {
  const token = keycloak?.tokenParsed
  if (token?.name) return token.name
  return `${token?.given_name || ''} ${token?.family_name || ''}`.trim() || username.value
})
const email = computed(() => keycloak?.tokenParsed?.email || 'user@example.com')
const role = computed(() => {
  // Keycloak 역할 가져오기 (realm_access.roles 또는 resource_access)
  const realmRoles = keycloak?.tokenParsed?.realm_access?.roles || []
  if (realmRoles.includes('admin')) return '관리자'
  if (realmRoles.includes('manager')) return '매니저'
  return '사용자'
})

// 메서드
const login = () => {
  keycloak?.login()
}

const logout = () => {
  isDropdownOpen.value = false
  keycloak?.logout()
}

const toggleDropdown = () => {
  isDropdownOpen.value = !isDropdownOpen.value
}

const goToProfile = () => {
  isDropdownOpen.value = false
  // TODO: 프로필 페이지로 이동
  console.log('프로필 페이지로 이동')
}

const goToSettings = () => {
  isDropdownOpen.value = false
  // TODO: 설정 페이지로 이동
  console.log('설정 페이지로 이동')
}

// 외부 클릭 시 드롭다운 닫기
const handleClickOutside = (event: MouseEvent) => {
  const target = event.target as HTMLElement
  if (!target.closest('.user-menu')) {
    isDropdownOpen.value = false
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onUnmounted(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>

