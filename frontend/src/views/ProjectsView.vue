<template>
  <div class="min-h-screen bg-gray-50 p-8">
    <div class="max-w-4xl mx-auto">
      <h1 class="text-3xl font-bold text-gray-900 mb-8">프로젝트 관리</h1>

      <!-- 생성 폼 -->
      <div class="bg-white rounded-lg shadow p-6 mb-8">
        <h2 class="text-xl font-semibold mb-4">새 프로젝트 생성</h2>
        <form @submit.prevent="handleCreate" class="space-y-4">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              프로젝트명 <span class="text-red-500">*</span>
            </label>
            <input
              v-model="form.name"
              type="text"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="프로젝트명 입력"
            />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">설명</label>
            <textarea
              v-model="form.description"
              rows="3"
              class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="프로젝트 설명 입력"
            />
          </div>

          <!-- 에러 표시 (Problem Details 기반) -->
          <div v-if="error" class="bg-red-50 border border-red-200 rounded-md p-4">
            <p class="text-red-800 font-medium">{{ error.title }}</p>
            <p class="text-red-600 text-sm">{{ error.detail }}</p>
            <p v-if="error.code" class="text-red-500 text-xs mt-1">코드: {{ error.code }}</p>
            <div v-if="error.errors" class="mt-2 space-y-1">
              <div v-for="err in error.errors" :key="err.field" class="text-red-600 text-sm">
                • {{ err.field }}: {{ err.message }}
              </div>
            </div>
            <p v-if="error.debugMessage" class="text-gray-500 text-xs mt-2">[디버그] {{ error.debugMessage }}</p>
          </div>

          <button
            type="submit"
            :disabled="loading"
            class="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed"
          >
            {{ loading ? '생성 중...' : '프로젝트 생성' }}
          </button>
        </form>
      </div>

      <!-- 목록 -->
      <div class="bg-white rounded-lg shadow p-6">
        <h2 class="text-xl font-semibold mb-4">프로젝트 목록</h2>
        <div v-if="loadingList" class="text-gray-500">로딩 중...</div>
        <div v-else-if="projects.length === 0" class="text-gray-500">프로젝트가 없습니다.</div>
        <div v-else class="space-y-3">
          <div
            v-for="project in projects"
            :key="project.id"
            class="border border-gray-200 rounded-md p-4 hover:bg-gray-50"
          >
            <h3 class="font-semibold text-lg">{{ project.name }}</h3>
            <p v-if="project.description" class="text-gray-600 mt-1">{{ project.description }}</p>
            <p class="text-gray-400 text-sm mt-2">생성일: {{ new Date(project.createdAt).toLocaleString('ko-KR') }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
/**
 * 프로젝트 목록/생성
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 */
import { ref, onMounted } from 'vue'
import { projectApi } from '@/api/project'
import type { Project, ProblemDetail } from '@/types/api'

const projects = ref<Project[]>([])
const loadingList = ref(false)
const loading = ref(false)
const error = ref<ProblemDetail | null>(null)

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
    await loadProjects()
  } catch (e) {
    error.value = e as ProblemDetail
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadProjects()
})
</script>

