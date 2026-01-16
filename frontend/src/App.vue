<template>
  <div class="min-h-screen bg-gradient-to-br from-gray-50 via-blue-50 to-indigo-50">
    <!-- 세련된 헤더 -->
    <header class="bg-white/80 backdrop-blur-md shadow-sm sticky top-0 z-40 border-b border-gray-200">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex justify-between items-center h-16">
          <!-- 로고 및 프로젝트명 -->
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-lg bg-gradient-to-br from-blue-600 to-indigo-600 flex items-center justify-center shadow-lg">
              <svg class="w-6 h-6 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            </div>
            <div>
              <h1 class="text-xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent">
                PMS
              </h1>
              <p class="text-xs text-gray-500">Project Management System</p>
            </div>
          </div>

          <!-- 네비게이션 (향후 추가) -->
          <nav class="hidden md:flex items-center gap-6">
            <router-link
              to="/"
              class="text-sm font-medium text-gray-700 hover:text-blue-600 transition-colors duration-150"
            >
              대시보드
            </router-link>
            <router-link
              to="/projects"
              class="text-sm font-medium text-gray-700 hover:text-blue-600 transition-colors duration-150"
            >
              프로젝트
            </router-link>
          </nav>

          <!-- 사용자 프로필 -->
          <UserProfile />
        </div>
      </div>
    </header>

    <!-- 메인 컨텐츠 -->
    <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <router-view />
    </main>

    <!-- 푸터 -->
    <footer class="mt-auto py-6 bg-white/50 backdrop-blur-sm border-t border-gray-200">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <p class="text-center text-sm text-gray-500">
          © 2026 PMS. All rights reserved.
        </p>
      </div>
    </footer>
  </div>
</template>

<script setup lang="ts">
/**
 * 루트 컴포넌트
 *
 * 세련된 레이아웃과 Keycloak SSO 인증 UI 포함
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 * @updated 2026-01-16 - Keycloak SSO UI 추가
 */
import UserProfile from './components/UserProfile.vue'
</script>

