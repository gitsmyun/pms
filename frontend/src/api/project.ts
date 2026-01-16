/**
 * 프로젝트 API
 *
 * Keycloak 토큰 자동 추가 (apiClient 사용)
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 * @updated 2026-01-16 - Axios 클라이언트로 변경
 */

import apiClient from './client'
import type { Project, CreateProjectRequest } from '@/types/api'

export const projectApi = {
  /**
   * 프로젝트 목록 조회
   */
  async list(): Promise<Project[]> {
    const response = await apiClient.get<Project[]>('/api/projects')
    return response.data
  },

  /**
   * 프로젝트 생성
   */
  async create(request: CreateProjectRequest): Promise<Project> {
    const response = await apiClient.post<Project>('/api/projects', request)
    return response.data
  },

  /**
   * 프로젝트 상세 조회
   */
  async getById(id: number): Promise<Project> {
    const response = await apiClient.get<Project>(`/api/projects/${id}`)
    return response.data
  }
}

