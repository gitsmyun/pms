<template>
  <!-- 세련된 사용자 프로필 드롭다운 -->
  <div class="relative" v-if="isAuthenticated">
    <!-- 프로필 버튼 -->
    <button
      @click="toggleDropdown"
      class="flex items-center gap-3 px-4 py-2.5 rounded-lg bg-gradient-to-r from-blue-600 to-indigo-600 text-white font-medium shadow-lg hover:shadow-xl hover:from-blue-700 hover:to-indigo-700 transition-all duration-200 transform hover:scale-105"
    >
      <!-- 사용자 아바타 -->
      <div class="w-8 h-8 rounded-full bg-white/20 flex items-center justify-center ring-2 ring-white/30">
        <svg class="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd" />
        </svg>
      </div>

      <!-- 사용자 이름 -->
      <span class="text-sm">{{ username }}</span>

      <!-- 드롭다운 아이콘 -->
      <svg
        class="w-4 h-4 transition-transform duration-200"
        :class="{ 'rotate-180': isDropdownOpen }"
        fill="none"
        stroke="currentColor"
        viewBox="0 0 24 24"
      >
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
      </svg>
    </button>

    <!-- 드롭다운 메뉴 -->
    <Transition
      enter-active-class="transition ease-out duration-200"
      enter-from-class="opacity-0 scale-95"
      enter-to-class="opacity-100 scale-100"
      leave-active-class="transition ease-in duration-150"
      leave-from-class="opacity-100 scale-100"
      leave-to-class="opacity-0 scale-95"
    >
      <div
        v-if="isDropdownOpen"
        class="absolute right-0 mt-2 w-64 bg-white rounded-xl shadow-2xl border border-gray-200 overflow-hidden z-50"
      >
        <!-- 사용자 정보 -->
        <div class="px-4 py-3 bg-gradient-to-r from-blue-50 to-indigo-50 border-b border-gray-200">
          <p class="text-sm font-semibold text-gray-900">{{ fullName }}</p>
          <p class="text-xs text-gray-600 mt-1">{{ email }}</p>
        </div>

        <!-- 메뉴 아이템 -->
        <div class="py-2">
          <button
            @click="logout"
            class="w-full px-4 py-2.5 text-left text-sm text-red-600 hover:bg-red-50 transition-colors duration-150 flex items-center gap-2"
          >
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
            </svg>
            로그아웃
          </button>
        </div>
      </div>
    </Transition>
  </div>

  <!-- 로그인 버튼 (미인증 시) -->
  <button
    v-else
    @click="login"
    class="flex items-center gap-2 px-6 py-2.5 rounded-lg bg-gradient-to-r from-blue-600 to-indigo-600 text-white font-medium shadow-lg hover:shadow-xl hover:from-blue-700 hover:to-indigo-700 transition-all duration-200 transform hover:scale-105"
  >
    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 16l-4-4m0 0l4-4m-4 4h14m-5 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h7a3 3 0 013 3v1" />
    </svg>
    로그인
  </button>
</template>

<script setup lang="ts">
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
const email = computed(() => keycloak?.tokenParsed?.email || '')

// 메서드
const login = () => {
  keycloak?.login()
}

const logout = () => {
  keycloak?.logout()
}

const toggleDropdown = () => {
  isDropdownOpen.value = !isDropdownOpen.value
}

// 외부 클릭 시 드롭다운 닫기
const handleClickOutside = (event: MouseEvent) => {
  const target = event.target as HTMLElement
  if (!target.closest('.relative')) {
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

