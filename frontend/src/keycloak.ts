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
 * ✅ 2026-02-05 변경사항:
 * - 로컬 개발 환경도 개발서버 Kubernetes Keycloak 사용
 * - Docker Compose Keycloak (8280, 8543)은 더 이상 사용하지 않음
 * - 모든 환경에서 https://10.127.6.102/keycloak 사용
 *
 * 접속 방법:
 * - 로컬 개발: http://localhost:5173 → https://10.127.6.102/keycloak (Kubernetes)
 * - 개발 서버: https://10.127.6.102 → https://10.127.6.102/keycloak (Kubernetes)
 */
const getKeycloakUrl = (): string => {
  const hostname = window.location.hostname
  const protocol = window.location.protocol

  console.log('🔍 [Keycloak Config] 현재 호스트:', hostname)
  console.log('🔍 [Keycloak Config] 프로토콜:', protocol)

  // ✅ 모든 환경에서 개발서버 Kubernetes Keycloak 사용
  console.log('✅ [Keycloak Config] Kubernetes Keycloak 사용 (Ingress 경로)')
  return 'https://10.127.6.102/keycloak'
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

