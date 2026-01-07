/**
 * API 호출 유틸
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 */

import type { Project, CreateProjectRequest, ProblemDetail } from '@/types/api'

const BASE_URL = '/api' // Vite Proxy 사용 (K8s 안전)

async function handleResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    const problem: ProblemDetail = await response.json()
    throw problem
  }
  return response.json()
}

export const projectApi = {
  async list(): Promise<Project[]> {
    const response = await fetch(`${BASE_URL}/projects`)
    return handleResponse(response)
  },

  async create(request: CreateProjectRequest): Promise<Project> {
    const response = await fetch(`${BASE_URL}/projects`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(request)
    })
    return handleResponse(response)
  },

  async getById(id: number): Promise<Project> {
    const response = await fetch(`${BASE_URL}/projects/${id}`)
    return handleResponse(response)
  }
}

