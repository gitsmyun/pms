/**
 * API 타입 정의
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 */

export interface Project {
  id: number
  name: string
  description: string | null
  createdAt: string
  updatedAt: string
}

export interface CreateProjectRequest {
  name: string
  description?: string
}

export interface ProblemDetail {
  type: string
  title: string
  status: number
  detail: string
  instance: string
  code?: string
  errors?: FieldError[]
  debugMessage?: string
  exception?: string
}

export interface FieldError {
  field: string
  message: string
  rejected?: any
}

