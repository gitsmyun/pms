/**
 * Keycloak 설정
 *
 * SSO (Single Sign-On) 인증을 위한 Keycloak 클라이언트 초기화
 *
 * @author 윤성민 책임
 * @since 2026-01-15
 * @updated 2026-01-19 - 동적 URL 설정 및 디버깅 강화
 */
import Keycloak from 'keycloak-js'

/**
 * 환경별 Keycloak URL 결정
 * - localhost: http://localhost:8280
 * - 개발 서버 IP (HTTPS): https://10.127.6.102:8543
 */
const getKeycloakUrl = (): string => {
  const hostname = window.location.hostname
  const protocol = window.location.protocol

  console.log('🔍 [Keycloak Config] 현재 호스트:', hostname)
  console.log('🔍 [Keycloak Config] 프로토콜:', protocol)

  // localhost 접속
  if (hostname === 'localhost' || hostname === '127.0.0.1') {
    console.log('✅ [Keycloak Config] localhost 모드')
    return 'http://localhost:8280'
  }

  // IP 접속 (개발 서버)
  if (hostname === '10.127.6.102') {
    // HTTPS로 접속했으면 Keycloak도 HTTPS
    if (protocol === 'https:') {
      console.log('✅ [Keycloak Config] 개발 서버 HTTPS 모드')
      return 'https://10.127.6.102:8543'
    }
    // HTTP로 접속했으면 Keycloak도 HTTP
    console.log('✅ [Keycloak Config] 개발 서버 HTTP 모드')
    return 'http://10.127.6.102:8280'
  }

  // 기타 (기본값)
  console.warn('⚠️ [Keycloak Config] 알 수 없는 호스트, 기본값 사용')
  return 'http://localhost:8280'
}

const keycloakUrl = getKeycloakUrl()
console.log('🔧 [Keycloak Config] 최종 Keycloak URL:', keycloakUrl)

const keycloak = new Keycloak({
  url: keycloakUrl,
  realm: 'pms',
  clientId: 'pms-frontend'
})

// 환경 정보 로깅
console.log('🌐 [Keycloak Config] 브라우저 환경:', {
  hostname: window.location.hostname,
  origin: window.location.origin,
  protocol: window.location.protocol,
  isSecureContext: window.isSecureContext,
  hasCrypto: !!window.crypto,
  hasSubtleCrypto: !!(window.crypto && window.crypto.subtle)
})

export default keycloak

