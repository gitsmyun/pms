/**
 * Keycloak 설정
 *
 * SSO (Single Sign-On) 인증을 위한 Keycloak 클라이언트 초기화
 *
 * @author 윤성민 책임
 * @since 2026-01-15
 */
import Keycloak from 'keycloak-js'

const keycloak = new Keycloak({
  url: 'http://localhost:8280',
  realm: 'pms',
  clientId: 'pms-frontend'
})

export default keycloak

