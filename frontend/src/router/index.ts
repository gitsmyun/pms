/**
 * 라우터 설정
 *
 * Keycloak 인증 가드 포함
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 * @updated 2026-01-16 - 인증 가드 추가
 */
import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import keycloak from '@/keycloak'
import ProjectsView from '@/views/ProjectsView.vue'

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'home',
    component: ProjectsView,
    meta: { requiresAuth: true } // 모든 페이지 인증 필요
  },
  {
    path: '/projects',
    name: 'projects',
    component: ProjectsView,
    meta: { requiresAuth: true } // 프로젝트는 인증 필요
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 전역 네비게이션 가드
// onLoad: 'login-required'가 이미 로그인을 강제하므로
// 이 가드는 추가 보안 레이어로만 작동
router.beforeEach((to, _from, next) => {
  // Keycloak 초기화가 완료될 때까지 대기
  if (!keycloak.authenticated && !keycloak.didInitialize) {
    console.warn('⏳ Keycloak 초기화 대기 중...')
    // Keycloak 초기화가 로그인을 처리함
    return
  }

  // 인증이 필요한 라우트인지 확인
  const requiresAuth = to.matched.some(record => record.meta.requiresAuth)

  if (requiresAuth && !keycloak.authenticated) {
    // 이론상 도달하지 않음 (onLoad: 'login-required'가 이미 처리)
    console.error('❌ 미인증 접근 시도 - 로그인 필요')
    keycloak.login({
      redirectUri: window.location.origin + to.fullPath
    })
    return
  }

  // 인증 불필요하거나 이미 인증됨
  next()
})

export default router

