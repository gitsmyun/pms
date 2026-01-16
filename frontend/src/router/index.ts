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
    meta: { requiresAuth: false } // 홈은 인증 불필요
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
router.beforeEach((to, _from, next) => {
  // 인증이 필요한 라우트인지 확인
  const requiresAuth = to.matched.some(record => record.meta.requiresAuth)

  if (requiresAuth && !keycloak.authenticated) {
    // 인증이 필요한데 로그인하지 않은 경우
    console.warn('인증 필요:', to.path)
    keycloak.login({
      redirectUri: window.location.origin + to.fullPath
    })
  } else {
    // 인증 불필요하거나 이미 인증됨
    next()
  }
})

export default router

