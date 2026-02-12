<template>
  <!-- 제미나이 스타일 레이아웃 -->
  <div class="app-layout">
    <!-- 메인 영역 (사이드바 + 컨텐츠) -->
    <div class="app-main">
      <!-- 좌측 사이드바 -->
      <aside class="sidebar" :class="{ collapsed: sidebarCollapsed }" id="sidebar">
        <!-- 사이드바 헤더 -->
        <div class="sidebar-header">
          <div class="sidebar-logo" @click="toggleSidebar">
            <div class="sidebar-logo-icon">P</div>
            <span class="sidebar-logo-text">PMS</span>
          </div>
        </div>

        <!-- 네비게이션 -->
        <nav class="sidebar-nav">
          <div class="nav-section">
            <div class="nav-section-title">메인</div>

            <div class="nav-item">
              <router-link to="/" class="nav-link" data-tooltip="대시보드">
                <span class="nav-icon">
                  <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                    <path d="M3 4a1 1 0 011-1h12a1 1 0 011 1v2a1 1 0 01-1 1H4a1 1 0 01-1-1V4zM3 10a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H4a1 1 0 01-1-1v-6zM14 9a1 1 0 00-1 1v6a1 1 0 001 1h2a1 1 0 001-1v-6a1 1 0 00-1-1h-2z"/>
                  </svg>
                </span>
                <span class="nav-text">대시보드</span>
              </router-link>
            </div>

            <div class="nav-item">
              <router-link to="/projects" class="nav-link" data-tooltip="프로젝트">
                <span class="nav-icon">
                  <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                    <path d="M9 2a2 2 0 00-2 2v8a2 2 0 002 2h6a2 2 0 002-2V6.414A2 2 0 0016.414 5L14 2.586A2 2 0 0012.586 2H9z"/>
                    <path d="M3 8a2 2 0 012-2v10h8a2 2 0 01-2 2H5a2 2 0 01-2-2V8z"/>
                  </svg>
                </span>
                <span class="nav-text">프로젝트</span>
              </router-link>
            </div>
          </div>

          <!-- 사용자관리 섹션 -->
          <div class="nav-section">
            <div class="nav-section-title">사용자관리</div>

            <div class="nav-item" :class="{ expanded: sampleMenuExpanded }">
              <div class="nav-link" @click="toggleSampleMenu" data-tooltip="예제 화면">
                <span class="nav-icon">
                  <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                    <path d="M9 4.804A7.968 7.968 0 005.5 4c-1.255 0-2.443.29-3.5.804v10A7.969 7.969 0 015.5 14c1.669 0 3.218.51 4.5 1.385A7.962 7.962 0 0114.5 14c1.255 0 2.443.29 3.5.804v-10A7.968 7.968 0 0014.5 4c-1.255 0-2.443.29-3.5.804V12a1 1 0 11-2 0V4.804z"/>
                  </svg>
                </span>
                <span class="nav-text">예제 화면</span>
                <span class="nav-arrow">
                  <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd"/>
                  </svg>
                </span>
              </div>
              <div class="nav-submenu">
                <router-link to="/samples/dashboard" class="nav-link">
                  <span class="nav-text">예제1: 대시보드</span>
                </router-link>
                <router-link to="/samples/statistics" class="nav-link">
                  <span class="nav-text">예제2: 통계</span>
                </router-link>
                <router-link to="/samples/todo" class="nav-link">
                  <span class="nav-text">예제3: TODO</span>
                </router-link>
              </div>
            </div>
          </div>
        </nav>

        <!-- 사이드바 푸터 -->
        <div class="sidebar-footer">
          <a href="#" class="sidebar-footer-link" data-tooltip="설정">
            <span class="nav-icon">
              <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M11.49 3.17c-.38-1.56-2.6-1.56-2.98 0a1.532 1.532 0 01-2.286.948c-1.372-.836-2.942.734-2.106 2.106.54.886.061 2.042-.947 2.287-1.561.379-1.561 2.6 0 2.978a1.532 1.532 0 01.947 2.287c-.836 1.372.734 2.942 2.106 2.106a1.532 1.532 0 012.287.947c.379 1.561 2.6 1.561 2.978 0a1.533 1.533 0 012.287-.947c1.372.836 2.942-.734 2.106-2.106a1.533 1.533 0 01.947-2.287c1.561-.379 1.561-2.6 0-2.978a1.532 1.532 0 01-.947-2.287c.836-1.372-.734-2.942-2.106-2.106a1.532 1.532 0 01-2.287-.947zM10 13a3 3 0 100-6 3 3 0 000 6z" clip-rule="evenodd"/>
              </svg>
            </span>
            <span class="nav-text">설정</span>
          </a>
        </div>
      </aside>

      <!-- 메인 컨텐츠 -->
      <main class="main-content">
        <!-- 헤더 -->
        <header class="main-header">
          <!-- 왼쪽 영역: ITCEN 로고 -->
          <div class="header-left">
            <a href="#" class="header-logo">
              <div class="header-logo-icon">IT</div>
              <div class="header-logo-text">
                <div class="header-logo-name">ITCEN</div>
                <div class="header-logo-subtitle">Project Manager</div>
              </div>
            </a>
          </div>

          <!-- 오른쪽 영역: 알림 + 사용자 -->
          <div class="header-right">
            <button class="mobile-menu-toggle" @click="toggleMobileSidebar">
              <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M3 5a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 10a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zM3 15a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1z" clip-rule="evenodd"/>
              </svg>
            </button>

            <!-- 알림 -->
            <div class="header-icon-btn">
              <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                <path d="M10 2a6 6 0 00-6 6v3.586l-.707.707A1 1 0 004 14h12a1 1 0 00.707-1.707L16 11.586V8a6 6 0 00-6-6zM10 18a3 3 0 01-3-3h6a3 3 0 01-3 3z"/>
              </svg>
              <span class="header-icon-badge">0</span>
            </div>

            <!-- 사용자 프로필 -->
            <UserProfile />
          </div>
        </header>

        <!-- 페이지 컨텐츠 -->
        <div class="page-content">
          <router-view />
        </div>

        <!-- 푸터 (main-content 내부 하단) -->
        <footer class="app-footer">
          <div class="footer-content">
            <div class="footer-bottom footer-compact">
              <div class="footer-copyright">
                © 2026 PMS. All rights reserved.
              </div>
            </div>
          </div>
        </footer>
      </main>
    </div><!-- app-main 종료 -->
  </div><!-- app-layout 종료 -->
</template>

<script setup lang="ts">
/**
 * 루트 컴포넌트 - 제미나이 스타일 레이아웃
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 * @updated 2026-02-11 - 제미나이 스타일 레이아웃 적용 + 샘플 HTML 메뉴 추가
 */
import { ref } from 'vue'
import UserProfile from './components/UserProfile.vue'

const sidebarCollapsed = ref(false)
const sampleMenuExpanded = ref(false)

function toggleSidebar() {
  sidebarCollapsed.value = !sidebarCollapsed.value
}

function toggleMobileSidebar() {
  const sidebar = document.getElementById('sidebar')
  sidebar?.classList.toggle('mobile-open')
}

function toggleSampleMenu() {
  sampleMenuExpanded.value = !sampleMenuExpanded.value
}
</script>

