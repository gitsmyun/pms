/**
 * 인증 유틸리티
 *
 * Keycloak 토큰 관리 및 API 호출 시 Authorization 헤더 추가
 *
 * @author 윤성민 책임
 * @since 2026-01-15
 */
import keycloak from '@/keycloak'

/**
 * API 호출 시 사용할 Headers 생성
 * Keycloak 인증된 경우 자동으로 Authorization 헤더 추가
 */
export function getAuthHeaders(): HeadersInit {
  const headers: HeadersInit = {
    'Content-Type': 'application/json'
  }

  // Keycloak 인증된 경우 토큰 추가
  if (keycloak.authenticated && keycloak.token) {
    headers['Authorization'] = `Bearer ${keycloak.token}`
  }

  return headers
}

/**
 * 토큰 갱신
 *
 * @param minValidity 최소 유효 시간 (초)
 * @returns 토큰 갱신 여부
 */
export async function refreshToken(minValidity: number = 30): Promise<boolean> {
  try {
    const refreshed = await keycloak.updateToken(minValidity)
    if (refreshed && keycloak.token) {
      console.log('Token refreshed successfully')
      localStorage.setItem('access_token', keycloak.token)
      return true
    }
    return false
  } catch (error) {
    console.error('Failed to refresh token', error)
    return false
  }
}

/**
 * 로그인
 */
export function login(): void {
  keycloak.login()
}

/**
 * 로그아웃
 */
export function logout(): void {
  keycloak.logout()
  localStorage.removeItem('access_token')
}

/**
 * 현재 사용자 정보 조회
 */
export function getCurrentUser() {
  if (!keycloak.authenticated) {
    return null
  }

  return {
    username: keycloak.tokenParsed?.preferred_username || '',
    email: keycloak.tokenParsed?.email || '',
    name: keycloak.tokenParsed?.name || '',
    roles: keycloak.tokenParsed?.realm_access?.roles || []
  }
}

