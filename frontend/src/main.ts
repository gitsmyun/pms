/**
 * 메인 엔트리
 *
 * Keycloak SSO 초기화 후 Vue 앱 마운트
 * - 최신 기업 표준 적용 (Silent SSO, URL 정리, 안전한 토큰 저장)
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 * @updated 2026-01-19 - 상세 디버깅 및 IP 접속 지원 강화
 */
import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import keycloak from './keycloak'
import './style.css'

/**
 * 🔍 브라우저 환경 상세 진단
 */
console.log('=' .repeat(80))
console.log('🚀 [PMS Frontend] 애플리케이션 시작')
console.log('=' .repeat(80))
console.log('📍 [환경 정보]')
console.log('  - URL:', window.location.href)
console.log('  - Origin:', window.location.origin)
console.log('  - Hostname:', window.location.hostname)
console.log('  - Protocol:', window.location.protocol)
console.log('  - Port:', window.location.port)
console.log('')
console.log('🔒 [보안 컨텍스트 확인]')
console.log('  - Secure Context:', window.isSecureContext)
console.log('  - Crypto API:', !!window.crypto)
console.log('  - SubtleCrypto API:', !!(window.crypto && window.crypto.subtle))
console.log('')

console.log('🔐 [PKCE 설정]')
console.log('  - PKCE Method: plain')
console.log('  - Flow: standard (Authorization Code)')
console.log('  💡 plain 방식: Web Crypto API 불필요 (localhost + IP 모두 동작)')
console.log('=' .repeat(80))
console.log('')

/**
 * Keycloak 초기화
 *
 * PKCE plain 방식 (모든 환경 통일):
 * - onLoad: 'login-required' - 미인증 시 자동 로그인 페이지로 이동
 * - flow: 'standard' - Authorization Code Flow (안정적)
 * - pkceMethod: 'plain' - Web Crypto API 불필요 (localhost + IP 모두 동작)
 *
 * 장점:
 * - localhost: 정상 동작 ✅
 * - HTTP + IP: 정상 동작 ✅ (Web Crypto API 불필요)
 * - PKCE 사용: 보안 유지 ✅
 *
 * 주의:
 * - plain은 S256보다 보안 약함 (개발 환경 OK, 프로덕션은 HTTPS + S256 권장)
 */

// 초기화 옵션 (모든 환경 동일)
const initOptions: any = {
  onLoad: 'login-required',
  redirectUri: window.location.origin + '/',

  // ✅ Standard Flow (모든 환경)
  flow: 'standard',

  // ✅ PKCE plain (Web Crypto API 불필요!)
  pkceMethod: 'plain',

  // ✅ responseMode 명시적 설정
  responseMode: 'fragment',

  // ✅ checkLoginIframe 비활성화 (IP 접속 시 타임아웃 방지)
  checkLoginIframe: false,

  // 디버깅 및 타임아웃 설정
  enableLogging: true,
  messageReceiveTimeout: 10000
}


console.log('🔧 [Keycloak Init] 초기화 옵션:', initOptions)
console.log('')

keycloak.init(initOptions).then((authenticated) => {
  console.log('=' .repeat(80))
  console.log('✅ [Keycloak Init] 초기화 완료')
  console.log('=' .repeat(80))
  console.log('  - 인증 상태:', authenticated ? '✅ 인증됨' : '❌ 미인증')

  // 로그인 필수 모드에서는 항상 authenticated === true
  if (!authenticated) {
    console.error('❌ [Keycloak Init] 인증 실패 - 로그인 필요')
    keycloak.login()
    return
  }

  // ✅ URL 파라미터 상세 분석
  console.log('')
  console.log('🔍 [URL 분석] 현재 URL 상태')
  console.log('  - Full URL:', window.location.href)
  console.log('  - Pathname:', window.location.pathname)
  console.log('  - Search:', window.location.search || '(없음)')
  console.log('  - Hash:', window.location.hash || '(없음)')

  // Query String 파라미터 파싱
  const urlParams = new URLSearchParams(window.location.search)
  const hasAuthParams = urlParams.has('code') ||
                         urlParams.has('state') ||
                         urlParams.has('session_state')

  console.log('  - OAuth 파라미터 존재:', hasAuthParams)
  if (hasAuthParams) {
    console.log('    • code:', urlParams.get('code') ? '✅ 있음' : '❌ 없음')
    console.log('    • state:', urlParams.get('state') ? '✅ 있음' : '❌ 없음')
    console.log('    • session_state:', urlParams.get('session_state') ? '✅ 있음' : '❌ 없음')
  }

  // Hash Fragment 파라미터 파싱
  const hashParams = new URLSearchParams(window.location.hash.substring(1))
  const hasHashAuthParams = hashParams.has('code') ||
                             hashParams.has('state') ||
                             hashParams.has('session_state')

  console.log('  - Hash OAuth 파라미터 존재:', hasHashAuthParams)
  if (hasHashAuthParams) {
    console.log('    • code:', hashParams.get('code') ? '✅ 있음' : '❌ 없음')
    console.log('    • state:', hashParams.get('state') ? '✅ 있음' : '❌ 없음')
    console.log('    • session_state:', hashParams.get('session_state') ? '✅ 있음' : '❌ 없음')
  }

  // ✅ URL 정리는 Vue Router 초기화 후 수행
  // (Vue Router가 초기 라우트를 설정한 이후에 정리)

  // 토큰 정보 로깅
  if (authenticated) {
    console.log('')
    console.log('🎫 [Token 정보]')
    console.log('  - Access Token:', keycloak.token ? '✅ 있음' : '❌ 없음')
    console.log('  - Refresh Token:', keycloak.refreshToken ? '✅ 있음' : '❌ 없음')
    console.log('  - ID Token:', keycloak.idToken ? '✅ 있음' : '❌ 없음')

    if (keycloak.tokenParsed) {
      console.log('  - 사용자:', keycloak.tokenParsed.preferred_username || keycloak.tokenParsed.sub)
      console.log('  - 만료 시간:', new Date((keycloak.tokenParsed.exp || 0) * 1000).toLocaleString())
      console.log('  - 발급 시간:', new Date((keycloak.tokenParsed.iat || 0) * 1000).toLocaleString())

      const now = Math.floor(Date.now() / 1000)
      const expiresIn = (keycloak.tokenParsed.exp || 0) - now
      console.log('  - 남은 시간:', Math.floor(expiresIn / 60), '분', expiresIn % 60, '초')
    }

    // 토큰 자동 갱신 설정
    console.log('')
    console.log('🔄 [Token 자동 갱신] 활성화')
    console.log('  - 갱신 간격: 60초마다 체크')
    console.log('  - 갱신 기준: 만료 70초 전')

    setInterval(() => {
      keycloak.updateToken(70).then((refreshed) => {
        if (refreshed) {
          console.log('🔄 [Token] 갱신됨:', new Date().toLocaleTimeString())
          if (keycloak.tokenParsed) {
            console.log('  - 새 만료 시간:', new Date((keycloak.tokenParsed.exp || 0) * 1000).toLocaleString())
          }
        }
      }).catch((error) => {
        console.error('❌ [Token] 갱신 실패:', error)
        console.error('  - 재로그인 필요')
        keycloak.login()
      })
    }, 60000)
  }

  console.log('=' .repeat(80))
  console.log('')

  // Vue 앱 생성 및 마운트
  console.log('🎨 [Vue] 앱 생성 및 마운트 시작...')
  const app = createApp(App)

  // Keycloak 인스턴스를 전역으로 제공
  app.provide('keycloak', keycloak)

  app.use(router)
  app.mount('#app')

  console.log('✅ [Vue] 앱 마운트 완료')

  // ✅ Vue Router 초기화 완료 후 URL 정리
  // nextTick을 사용하여 Router가 완전히 준비될 때까지 대기
  router.isReady().then(() => {
    console.log('')
    console.log('🧹 [URL 정리] Vue Router 준비 완료, URL 정리 시작')

    // OAuth 파라미터 확인
    const urlParams = new URLSearchParams(window.location.search)
    const hasAuthParams = urlParams.has('code') ||
                           urlParams.has('state') ||
                           urlParams.has('session_state')

    const hashParams = new URLSearchParams(window.location.hash.substring(1))
    const hasHashAuthParams = hashParams.has('code') ||
                               hashParams.has('state') ||
                               hashParams.has('session_state')

    // OAuth 파라미터가 있으면 정리
    if (hasAuthParams || hasHashAuthParams) {
      console.log('  - OAuth 파라미터 감지:', {
        query: hasAuthParams,
        hash: hasHashAuthParams
      })

      // Router의 현재 경로 (파라미터 제외)
      const currentPath = router.currentRoute.value.path

      console.log('  - 이전 URL:', window.location.href)
      console.log('  - 정리 후 경로:', currentPath)

      // Router의 replace를 사용하여 깔끔하게 정리
      router.replace({
        path: currentPath,
        query: {},  // 모든 query 파라미터 제거
        hash: ''    // hash 제거
      }).then(() => {
        console.log('  ✅ URL 정리 완료 (Router 사용)')
        console.log('  - 최종 URL:', window.location.href)
      }).catch((err) => {
        console.warn('  ⚠️ URL 정리 중 오류:', err)
        // Fallback: 직접 replaceState 사용
        const cleanUrl = window.location.origin + currentPath
        window.history.replaceState({}, document.title, cleanUrl)
        console.log('  ✅ URL 정리 완료 (Fallback)')
      })
    } else {
      console.log('  ✅ OAuth 파라미터 없음, URL 정리 불필요')
    }
  })

  console.log('=' .repeat(80))
}).catch((error) => {
  console.error('=' .repeat(80))
  console.error('❌ [Keycloak Init] 초기화 실패')
  console.error('=' .repeat(80))
  console.error('  - Error:', error)
  console.error('  - Message:', error.message)
  console.error('  - Stack:', error.stack)

  // Web Crypto API 오류 특별 처리
  if (error.message && error.message.includes('Web Crypto API')) {
    console.error('')
    console.error('🔴 [진단] Web Crypto API 오류 감지')
    console.error('=' .repeat(80))
    console.error('📋 원인:')
    console.error('  HTTP 환경에서 IP 주소로 접속하면 Web Crypto API를 사용할 수 없습니다.')
    console.error('  PKCE (pkceMethod: S256)는 Web Crypto API가 필요합니다.')
    console.error('')
    console.error('💡 해결 방법:')
    console.error('  1. HTTPS 적용 (권장)')
    console.error('     - Nginx에서 자체 서명 인증서 사용')
    console.error('     - Let\'s Encrypt 무료 인증서 사용')
    console.error('')
    console.error('  2. localhost로 접속')
    console.error('     - http://localhost:8181 (현재 동작 중)')
    console.error('')
    console.error('  3. PKCE 비활성화 (임시 방편, 보안 약화)')
    console.error('     - Keycloak 클라이언트 설정에서 PKCE 선택 해제')
    console.error('')
    console.error('🌐 현재 환경:')
    console.error('  - URL:', window.location.href)
    console.error('  - Protocol:', window.location.protocol)
    console.error('  - Hostname:', window.location.hostname)
    console.error('  - Secure Context:', window.isSecureContext)
    console.error('  - Crypto API:', !!window.crypto)
    console.error('  - SubtleCrypto:', !!(window.crypto && window.crypto.subtle))
    console.error('=' .repeat(80))
  }

  console.error('=' .repeat(80))
})




