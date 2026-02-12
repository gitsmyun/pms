<template>
  <!-- 페이지 컨테이너 -->
  <div class="page-container">
    <!-- 페이지 헤더 -->
    <div class="page-header">
      <div class="page-title-wrapper">
        <h1 class="text-h2">프로젝트 관리</h1>
        <button @click="showCreateForm = !showCreateForm" class="btn btn-primary">
          <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd"/>
          </svg>
          새 프로젝트 생성
        </button>
      </div>
      <p class="page-description">새로운 프로젝트를 생성하고 관리합니다.</p>
    </div>

    <!-- 생성 폼 (토글 가능) -->
    <div v-if="showCreateForm" class="card mb-8 animate-slide-in-down">
      <div class="card-header">
        <h2 class="card-title">새 프로젝트 생성</h2>
      </div>
      <div class="card-body">
        <form @submit.prevent="handleCreate">
          <div class="form-row">
            <div class="form-group">
              <label class="form-label form-label-required">
                프로젝트명
              </label>
              <input
                v-model="form.name"
                type="text"
                class="form-input"
                :class="{ 'form-input-error': error?.errors?.find(e => e.field === 'name') }"
                placeholder="프로젝트명을 입력하세요"
              />
              <span v-if="error?.errors?.find(e => e.field === 'name')" class="form-error">
                {{ error.errors.find(e => e.field === 'name')?.message }}
              </span>
            </div>
          </div>

          <div class="form-group">
            <label class="form-label">설명</label>
            <textarea
              v-model="form.description"
              rows="3"
              class="form-textarea"
              placeholder="프로젝트 설명을 입력하세요 (선택사항)"
            />
            <span class="form-help">선택 사항입니다.</span>
          </div>

          <!-- 에러 표시 (Problem Details 기반) -->
          <div v-if="error" class="alert-card alert-card-danger mb-4">
            <span class="alert-card-icon">
              <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
              </svg>
            </span>
            <div class="alert-card-content">
              <div class="alert-card-title">{{ error.title }}</div>
              <div class="alert-card-message">{{ error.detail }}</div>
              <p v-if="error.code" class="text-body-xs mt-1">코드: {{ error.code }}</p>
              <p v-if="error.debugMessage" class="text-body-xs mt-2">[디버그] {{ error.debugMessage }}</p>
            </div>
          </div>

          <div class="form-actions form-actions-end">
            <button
              type="button"
              @click="showCreateForm = false"
              class="btn btn-ghost"
            >
              취소
            </button>
            <button
              type="submit"
              :disabled="loading"
              class="btn btn-primary"
              :class="{ 'btn-loading': loading }"
            >
              {{ loading ? '생성 중...' : '프로젝트 생성' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- 프로젝트 목록 -->
    <div class="section">
      <div class="section-header">
        <div>
          <h2 class="section-title">프로젝트 목록</h2>
          <p class="section-subtitle">전체 {{ projects.length }}개의 프로젝트</p>
        </div>
      </div>

      <!-- 로딩 상태 -->
      <div v-if="loadingList" class="empty-state">
        <div class="skeleton skeleton-circle" style="width: 64px; height: 64px; margin: 0 auto 1rem;"></div>
        <div class="skeleton skeleton-text" style="width: 200px; margin: 0 auto;"></div>
        <p class="text-muted mt-4">로딩 중...</p>
      </div>

      <!-- 빈 상태 -->
      <div v-else-if="projects.length === 0" class="empty-state">
        <div class="empty-state-icon">
          <svg viewBox="0 0 20 20" fill="currentColor">
            <path d="M9 2a2 2 0 00-2 2v8a2 2 0 002 2h6a2 2 0 002-2V6.414A2 2 0 0016.414 5L14 2.586A2 2 0 0012.586 2H9z"/>
            <path d="M3 8a2 2 0 012-2v10h8a2 2 0 01-2 2H5a2 2 0 01-2-2V8z"/>
          </svg>
        </div>
        <div class="empty-state-title">프로젝트가 없습니다</div>
        <div class="empty-state-message">
          새 프로젝트를 생성하여 시작해보세요.
        </div>
        <button @click="showCreateForm = true" class="btn btn-primary mt-4">
          <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd"/>
          </svg>
          첫 프로젝트 만들기
        </button>
      </div>

      <!-- 프로젝트 카드 그리드 -->
      <div v-else class="grid grid-cols-3 md:grid-cols-2 gap-4">
        <div
          v-for="project in projects"
          :key="project.id"
          class="card card-clickable hover-lift"
        >
          <div class="card-body">
            <div class="flex items-start justify-between mb-3">
              <div class="flex-1">
                <h3 class="text-h4 mb-2">{{ project.name }}</h3>
                <p v-if="project.description" class="text-body-sm text-muted line-clamp-2">
                  {{ project.description }}
                </p>
              </div>
              <span class="badge badge-success badge-pill">활성</span>
            </div>

            <div class="divider my-4"></div>

            <div class="flex items-center justify-between">
              <div class="text-body-xs text-muted">
                생성일: {{ formatDate(project.createdAt) }}
              </div>
              <div class="flex items-center gap-2">
                <button class="btn btn-ghost btn-icon btn-sm" title="수정">
                  <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
                    <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z"/>
                  </svg>
                </button>
                <button class="btn btn-ghost btn-icon btn-sm" title="삭제">
                  <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clip-rule="evenodd"/>
                  </svg>
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
/**
 * 프로젝트 목록/생성 - 최신 웹 프로젝트 스타일
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 * @updated 2026-02-11 - 최신 웹 프로젝트 스타일 적용
 */
import { ref, onMounted } from 'vue'
import { projectApi } from '@/api/project'
import type { Project, ProblemDetail } from '@/types/api'

const projects = ref<Project[]>([])
const loadingList = ref(false)
const loading = ref(false)
const error = ref<ProblemDetail | null>(null)
const showCreateForm = ref(false)

const form = ref({
  name: '',
  description: ''
})

async function loadProjects() {
  loadingList.value = true
  try {
    projects.value = await projectApi.list()
  } catch (e) {
    console.error('목록 로드 실패:', e)
  } finally {
    loadingList.value = false
  }
}

async function handleCreate() {
  loading.value = true
  error.value = null
  try {
    await projectApi.create({
      name: form.value.name,
      description: form.value.description || undefined
    })
    form.value = { name: '', description: '' }
    showCreateForm.value = false
    await loadProjects()
  } catch (e) {
    error.value = e as ProblemDetail
  } finally {
    loading.value = false
  }
}

function formatDate(dateString: string) {
  return new Date(dateString).toLocaleDateString('ko-KR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

onMounted(() => {
  loadProjects()
})
</script>

