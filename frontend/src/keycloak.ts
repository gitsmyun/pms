/**
 * Keycloak 설정
 *
 * SSO (Single Sign-On) 인증을 위한 Keycloak 클라이언트 초기화
 *
 * @author 윤성민 책임
 * @since 2026-01-15
 * @updated 2026-02-05 - Kubernetes Keycloak 통합 사용 (로컬/개발서버 모두)
 */
import Keycloak from 'keycloak-js'

/**
 * Keycloak URL 결정
 *
 * ✅ 2026-02-06 변경사항:
 * - Kubernetes Ingress 경로 사용: /keycloak
 * - 상대 경로 사용으로 localhost, IP, 도메인 모두 지원
 * - Protocol(http/https) 자동 감지
 *
 * 접속 방법:
 * - 로컬 개발: http://localhost:5173 → http://localhost/keycloak (Ingress proxy)
 * - 개발 서버: https://10.127.6.102 → https://10.127.6.102/keycloak (Ingress)
 */
const getKeycloakUrl = (): string => {
  const hostname = window.location.hostname
  const protocol = window.location.protocol
  const port = window.location.port

  console.log('🔍 [Keycloak Config] 현재 호스트:', hostname)
  console.log('🔍 [Keycloak Config] 프로토콜:', protocol)
  console.log('🔍 [Keycloak Config] 포트:', port || '(기본)')

  // ✅ 상대 경로 사용 - 브라우저가 현재 origin 기준으로 자동 해석
  // localhost:5173 → localhost/keycloak (Vite proxy를 통해 10.127.6.102로 전달)
  // 10.127.6.102 → 10.127.6.102/keycloak (직접 접속)
  if (hostname === 'localhost' || hostname === '127.0.0.1') {
    console.log('✅ [Keycloak Config] 로컬 개발 환경 - 개발서버 Keycloak 사용')
    return `${protocol}//10.127.6.102/keycloak`
  }

  console.log('✅ [Keycloak Config] 개발서버 환경 - 상대 경로 사용')
  return `${protocol}//${hostname}/keycloak`
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

