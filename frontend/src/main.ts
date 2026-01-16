/**
 * 메인 엔트리
 *
 * Keycloak SSO 초기화 후 Vue 앱 마운트
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 * @updated 2026-01-16 - Keycloak SSO 연동
 */
import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import keycloak from './keycloak'
import './style.css'

/**
 * Keycloak 초기화
 * - check-sso: 기존 세션 확인 (자동 로그인)
 * - onLoad: 'check-sso' - 로그인 강제하지 않음
 */
keycloak.init({
  onLoad: 'check-sso',
  checkLoginIframe: false, // iframe 체크 비활성화 (성능 개선)
  pkceMethod: 'S256' // PKCE 사용 (보안 강화)
}).then((authenticated) => {
  console.log(`Keycloak 초기화 완료: ${authenticated ? '인증됨' : '미인증'}`)

  // 토큰 자동 갱신 (만료 70초 전)
  if (authenticated) {
    setInterval(() => {
      keycloak.updateToken(70).then((refreshed) => {
        if (refreshed) {
          console.log('토큰 갱신됨')
        }
      }).catch(() => {
        console.error('토큰 갱신 실패')
      })
    }, 60000) // 60초마다 체크
  }

  // Vue 앱 생성 및 마운트
  const app = createApp(App)

  // Keycloak 인스턴스를 전역으로 제공
  app.provide('keycloak', keycloak)

  app.use(router)
  app.mount('#app')
}).catch((error) => {
  console.error('Keycloak 초기화 실패:', error)
})


