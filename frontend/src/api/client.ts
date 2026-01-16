/**
 * Axios 클라이언트 설정
 *
 * Keycloak 토큰을 자동으로 추가하는 Interceptor 포함
 *
 * @author 윤성민 책임
 * @since 2026-01-16
 */
import axios from 'axios'
import keycloak from '../keycloak'

// Axios 인스턴스 생성
const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://localhost:8180',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json'
  }
})

// Request Interceptor: 토큰 자동 추가
apiClient.interceptors.request.use(
  (config) => {
    if (keycloak.token) {
      config.headers.Authorization = `Bearer ${keycloak.token}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response Interceptor: 401 에러 시 로그인 리다이렉트
apiClient.interceptors.response.use(
  (response) => {
    return response
  },
  async (error) => {
    if (error.response?.status === 401) {
      console.warn('401 Unauthorized - 로그인 필요')

      // 토큰 갱신 시도
      try {
        const refreshed = await keycloak.updateToken(5)
        if (refreshed) {
          console.log('토큰 갱신 성공, 요청 재시도')
          // 원래 요청 재시도
          const config = error.config
          config.headers.Authorization = `Bearer ${keycloak.token}`
          return apiClient.request(config)
        }
      } catch (e) {
        console.error('토큰 갱신 실패, 로그인 필요')
        // 로그인 페이지로 리다이렉트
        await keycloak.login()
      }
    }
    return Promise.reject(error)
  }
)

export default apiClient

