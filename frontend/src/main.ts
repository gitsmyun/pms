/**
 * 메인 엔트리
 *
 * Keycloak SSO 초기화 후 Vue 앱 마운트
 * - 최신 기업 표준 적용 (Silent SSO, URL 정리, 안전한 토큰 저장)
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
 *
 * 최신 기업 표준 설정:
 * - onLoad: 'login-required' - 미인증 시 자동 로그인 페이지로 이동
 * - flow: 'standard' - Authorization Code Flow (가장 안전)
 * - redirectUri: 명시적 설정으로 로그인 후 원래 페이지로 복귀
 */
keycloak.init({
  onLoad: 'login-required', // ✅ 로그인 필수 - 미인증 시 자동 리다이렉트
  redirectUri: window.location.origin + '/', // 로그인 후 홈으로 복귀
  pkceMethod: 'S256', // PKCE 사용 (OAuth 2.1 표준)
  flow: 'standard', // Authorization Code Flow
  checkLoginIframe: true, // Silent SSO 체크 활성화
  checkLoginIframeInterval: 5, // 5초마다 세션 체크
  silentCheckSsoRedirectUri: window.location.origin + '/silent-check-sso.html',

  // 토큰 저장 방식 (기업 표준)
  enableLogging: import.meta.env.DEV // 개발 환경에서만 로깅
}).then((authenticated) => {
  console.log(`✅ Keycloak 초기화 완료: ${authenticated ? '인증됨' : '미인증'}`)

  // 로그인 필수 모드에서는 항상 authenticated === true
  if (!authenticated) {
    console.error('❌ 인증 실패 - 로그인 필요')
    keycloak.login()
    return
  }

  // URL에서 인증 코드 파라미터 제거 (보안 강화)
  if (window.location.hash && (window.location.hash.includes('code=') || window.location.hash.includes('state='))) {
    // Hash fragment를 제거하고 깨끗한 URL로 이동
    const cleanUrl = window.location.origin + window.location.pathname
    window.history.replaceState({}, document.title, cleanUrl)
    console.log('✅ URL 정리 완료: 인증 코드 제거됨')
  }

  // 토큰 자동 갱신 설정
  if (authenticated) {
    // 토큰 정보 로깅 (개발 환경에서만)
    if (import.meta.env.DEV) {
      console.log('토큰 저장 위치:', keycloak.tokenParsed ? 'Memory (SessionStorage 백업)' : 'N/A')
      console.log('토큰 만료:', new Date((keycloak.tokenParsed?.exp || 0) * 1000).toLocaleString())
    }

    // 토큰 자동 갱신 (만료 70초 전)
    setInterval(() => {
      keycloak.updateToken(70).then((refreshed) => {
        if (refreshed) {
          console.log('🔄 토큰 갱신됨:', new Date().toLocaleTimeString())
        }
      }).catch(() => {
        console.error('❌ 토큰 갱신 실패 - 재로그인 필요')
        keycloak.login()
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
  console.error('❌ Keycloak 초기화 실패:', error)
})




