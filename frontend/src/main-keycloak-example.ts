/**
 * Keycloak 통합 예제
 *
 * main.ts에서 Keycloak를 초기화하는 방법을 보여주는 예제 코드
 *
 * 사용 방법:
 * 1. 이 파일의 내용을 main.ts에 복사
 * 2. 또는 필요한 부분만 발췌하여 사용
 *
 * @author 윤성민 책임
 * @since 2026-01-15
 */

import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import keycloak from './keycloak'
import { refreshToken } from './utils/auth'
import './style.css'

/**
 * Option 1: SSO 필수 (로그인 없이 앱 사용 불가)
 *
 * onLoad: 'login-required' 사용
 */
export function initWithLoginRequired() {
  keycloak.init({
    onLoad: 'login-required',  // 로그인 필수
    checkLoginIframe: false,
    pkceMethod: 'S256'  // PKCE 사용 (보안 강화)
  }).then((authenticated) => {
    if (!authenticated) {
      console.error('User not authenticated')
      return
    }

    console.log('Keycloak authenticated:', authenticated)

    // 토큰 저장
    if (keycloak.token) {
      localStorage.setItem('access_token', keycloak.token)
    }

    // Vue 앱 초기화
    const app = createApp(App)
    app.use(router)
    app.mount('#app')

    // 토큰 자동 갱신 (5분마다)
    setupTokenRefresh()
  }).catch((error) => {
    console.error('Keycloak initialization failed', error)
  })
}

/**
 * Option 2: SSO 선택적 (로그인 없이도 일부 기능 사용 가능)
 *
 * onLoad: 'check-sso' 사용
 */
export function initWithCheckSSO() {
  keycloak.init({
    onLoad: 'check-sso',  // SSO 확인만 (로그인 강제 안 함)
    checkLoginIframe: false,
    pkceMethod: 'S256'
  }).then((authenticated) => {
    console.log('Keycloak initialized. Authenticated:', authenticated)

    // 인증된 경우 토큰 저장
    if (authenticated && keycloak.token) {
      localStorage.setItem('access_token', keycloak.token)
    }

    // Vue 앱 초기화 (인증 여부와 무관)
    const app = createApp(App)
    app.use(router)
    app.mount('#app')

    // 토큰 자동 갱신 (인증된 경우만)
    if (authenticated) {
      setupTokenRefresh()
    }
  }).catch((error) => {
    console.error('Keycloak initialization failed', error)

    // 초기화 실패해도 앱은 시작 (SSO 없이)
    const app = createApp(App)
    app.use(router)
    app.mount('#app')
  })
}

/**
 * Option 3: SSO 비활성화 (기존 방식)
 *
 * Keycloak 초기화하지 않음
 */
export function initWithoutSSO() {
  const app = createApp(App)
  app.use(router)
  app.mount('#app')
}

/**
 * 토큰 자동 갱신 설정
 */
function setupTokenRefresh() {
  // 5분마다 토큰 갱신 시도
  setInterval(async () => {
    const refreshed = await refreshToken(30)  // 30초 이내 만료 시 갱신
    if (refreshed) {
      console.log('Token auto-refreshed')
    }
  }, 300000)  // 5분

  // 브라우저 탭 활성화 시에도 토큰 갱신
  document.addEventListener('visibilitychange', async () => {
    if (document.visibilityState === 'visible') {
      await refreshToken(30)
    }
  })
}

/**
 * 환경변수 기반 초기화 (권장)
 */
function initializeApp() {
  // 환경변수로 SSO 활성화 여부 결정
  const ssoEnabled = import.meta.env.VITE_SSO_ENABLED === 'true'
  const ssoRequired = import.meta.env.VITE_SSO_REQUIRED === 'true'

  if (!ssoEnabled) {
    // SSO 비활성화
    initWithoutSSO()
  } else if (ssoRequired) {
    // SSO 필수
    initWithLoginRequired()
  } else {
    // SSO 선택적
    initWithCheckSSO()
  }
}

// 앱 초기화 실행
initializeApp()

