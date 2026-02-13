<template>
  <div class="page-container">
    <!-- 페이지 헤더 -->
    <div class="page-header">
      <div class="page-title-wrapper">
        <h1 class="text-h2">TODO LIST</h1>
        <span class="badge badge-pill badge-primary ml-3">{{ todayDate }}</span>
      </div>
      <div class="flex gap-2 items-center">
        <button class="btn btn-ghost btn-icon" title="새로고침" @click="refreshTodos">
          <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M4 2a1 1 0 011 1v2.101a7.002 7.002 0 0111.601 2.566 1 1 0 11-1.885.666A5.002 5.002 0 005.999 7H9a1 1 0 010 2H4a1 1 0 01-1-1V3a1 1 0 011-1zm.008 9.057a1 1 0 011.276.61A5.002 5.002 0 0014.001 13H11a1 1 0 110-2h5a1 1 0 011 1v5a1 1 0 11-2 0v-2.101a7.002 7.002 0 01-11.601-2.566 1 1 0 01.61-1.276z" clip-rule="evenodd"/>
          </svg>
        </button>
        <button class="btn btn-primary" @click="showAddTodoModal">
          <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd"/>
          </svg>
          새 TODO 추가
        </button>
      </div>
    </div>
    <div class="page-description mb-6">
      <svg class="page-description-icon" viewBox="0 0 20 20" fill="currentColor">
        <path fill-rule="evenodd" d="M6.267 3.455a3.066 3.066 0 001.745-.723 3.066 3.066 0 013.976 0 3.066 3.066 0 001.745.723 3.066 3.066 0 012.812 2.812c.051.643.304 1.254.723 1.745a3.066 3.066 0 010 3.976 3.066 3.066 0 00-.723 1.745 3.066 3.066 0 01-2.812 2.812 3.066 3.066 0 00-1.745.723 3.066 3.066 0 01-3.976 0 3.066 3.066 0 00-1.745-.723 3.066 3.066 0 01-2.812-2.812 3.066 3.066 0 00-.723-1.745 3.066 3.066 0 010-3.976 3.066 3.066 0 00.723-1.745 3.066 3.066 0 012.812-2.812zm7.44 5.252a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
      </svg>
      <span><strong>TODO 카드를 드래그</strong>하여 <strong>승인자 영역</strong>으로 이동하면 <strong>즉시 자동 승인</strong>됩니다 <span class="page-description-divider">•</span> <span class="page-description-time">최종 업데이트: {{ lastUpdateTime }}</span></span>
    </div>

    <!-- 통계 카드 -->
    <div class="todo-stats">
      <div class="metric-card animate-stagger metric-card-primary" style="animation-delay: 0s;">
        <div class="stat-widget-header">
          <span class="stat-widget-title">대기 중</span>
        </div>
        <div class="stat-widget-value">{{ pendingTodos.length }}</div>
        <div class="stat-widget-change up">+{{ todayNewCount }} 신규</div>
      </div>
      <div class="metric-card animate-stagger metric-card-success" style="animation-delay: 0.1s;">
        <div class="stat-widget-header">
          <span class="stat-widget-title">승인 완료</span>
        </div>
        <div class="stat-widget-value">{{ approvedTodos.length }}</div>
        <div class="stat-widget-change up">{{ approvalRate }}% 승인율</div>
      </div>
      <div class="metric-card animate-stagger metric-card-danger" style="animation-delay: 0.2s;">
        <div class="stat-widget-header">
          <span class="stat-widget-title">거부됨</span>
        </div>
        <div class="stat-widget-value">{{ rejectedTodos.length }}</div>
        <div class="stat-widget-change">검토 필요</div>
      </div>
      <div class="metric-card animate-stagger metric-card-info" style="animation-delay: 0.3s;">
        <div class="stat-widget-header">
          <span class="stat-widget-title">평균 처리 시간</span>
        </div>
        <div class="stat-widget-value" style="font-size: 1.75rem;">{{ avgProcessTime }}분</div>
        <div class="stat-widget-change down">-15% 개선</div>
      </div>
    </div>

    <!-- 필터 바 -->
    <div class="todo-filter-bar">
      <div class="todo-filter-group">
        <span class="todo-filter-label">우선순위:</span>
        <button v-for="priority in priorities" :key="priority.value"
                class="todo-filter-btn"
                :class="{ active: selectedPriority === priority.value }"
                @click="selectedPriority = priority.value">
          {{ priority.label }}
        </button>
      </div>
      <div class="todo-filter-group">
        <span class="todo-filter-label">담당자:</span>
        <button v-for="assignee in assignees" :key="assignee.id"
                class="todo-filter-btn"
                :class="{ active: selectedAssignee === assignee.id }"
                @click="selectedAssignee = assignee.id">
          {{ assignee.name }}
        </button>
      </div>
      <div class="form-group mb-0">
        <input type="search"
               class="form-input form-input-sm"
               placeholder="TODO 검색..."
               v-model="searchQuery"
               style="min-width: 200px;">
      </div>
    </div>

    <!-- 드래그 앤 드롭 영역 -->
    <div class="drag-container">
      <!-- 대기 중 컬럼 -->
      <div class="todo-column pending"
           :class="{ 'drop-active': isDraggingOver === 'pending' }"
           @dragover.prevent="handleDragOver('pending')"
           @dragleave="handleDragLeave"
           @drop="handleDrop('pending', $event)">
        <div class="todo-column-header">
          <div class="todo-column-title">
            <div class="todo-column-icon">
              <svg width="18" height="18" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd"/>
              </svg>
            </div>
            <span>대기 중</span>
          </div>
          <span class="todo-column-count">{{ filteredPendingTodos.length }}</span>
        </div>
        <div class="todo-list">
          <div v-if="filteredPendingTodos.length === 0" class="todo-empty">
            <svg class="todo-empty-icon" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
            </svg>
            <p class="todo-empty-text">대기 중인 TODO가 없습니다</p>
          </div>
          <div v-for="todo in filteredPendingTodos" :key="todo.id"
               class="todo-card"
               :class="[`priority-${todo.priority}`, { dragging: draggedTodo?.id === todo.id }]"
               draggable="true"
               @dragstart="handleDragStart(todo, $event)"
               @dragend="handleDragEnd">
            <div class="todo-card-header">
              <h3 class="todo-card-title">{{ todo.title }}</h3>
              <div class="todo-card-actions">
                <button class="todo-card-action-btn" title="수정" @click="editTodo(todo)">
                  <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
                    <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z"/>
                  </svg>
                </button>
                <button class="todo-card-action-btn danger" title="삭제" @click="deleteTodo(todo.id)">
                  <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clip-rule="evenodd"/>
                  </svg>
                </button>
              </div>
            </div>
            <div class="todo-card-body">
              <p class="todo-card-description">{{ todo.description }}</p>
              <div class="todo-card-meta">
                <div class="todo-card-meta-item">
                  <svg class="todo-card-meta-icon" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clip-rule="evenodd"/>
                  </svg>
                  <span>{{ todo.dueDate }}</span>
                </div>
                <div class="todo-card-meta-item">
                  <svg class="todo-card-meta-icon" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd"/>
                  </svg>
                  <span>{{ todo.estimatedTime }}시간</span>
                </div>
                <div class="todo-card-meta-item">
                  <span class="badge" :class="`badge-${getPriorityBadgeClass(todo.priority)}`">{{ getPriorityLabel(todo.priority) }}</span>
                </div>
              </div>
            </div>
            <div class="todo-card-footer">
              <div class="todo-card-assignee">
                <div class="todo-card-avatar" :style="{ background: todo.assignee.color }">
                  {{ todo.assignee.initials }}
                </div>
                <span class="todo-card-assignee-name">{{ todo.assignee.name }}</span>
              </div>
              <div class="todo-card-tags">
                <span v-for="tag in todo.tags" :key="tag" class="todo-card-tag">{{ tag }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 승인됨 컬럼 -->
      <div class="todo-column approved"
           :class="{ 'drop-active': isDraggingOver === 'approved' }"
           @dragover.prevent="handleDragOver('approved')"
           @dragleave="handleDragLeave"
           @drop="handleDrop('approved', $event)">
        <div class="todo-column-header">
          <div class="todo-column-title">
            <div class="todo-column-icon">
              <svg width="18" height="18" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
              </svg>
            </div>
            <span>승인됨</span>
          </div>
          <span class="todo-column-count">{{ filteredApprovedTodos.length }}</span>
        </div>
        <div class="todo-list">
          <div v-if="filteredApprovedTodos.length === 0" class="todo-empty">
            <svg class="todo-empty-icon" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
            </svg>
            <p class="todo-empty-text">승인된 TODO가 없습니다<br>왼쪽 카드를 드래그하여 승인하세요</p>
          </div>
          <div v-for="todo in filteredApprovedTodos" :key="todo.id"
               class="todo-card"
               :class="[`priority-${todo.priority}`, { dragging: draggedTodo?.id === todo.id }]"
               draggable="true"
               @dragstart="handleDragStart(todo, $event)"
               @dragend="handleDragEnd">
            <div class="todo-card-header">
              <h3 class="todo-card-title">{{ todo.title }}</h3>
              <div class="todo-card-actions">
                <button class="todo-card-action-btn danger" title="삭제" @click="deleteTodo(todo.id)">
                  <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clip-rule="evenodd"/>
                  </svg>
                </button>
              </div>
            </div>
            <div class="todo-card-body">
              <p class="todo-card-description">{{ todo.description }}</p>
              <div class="todo-card-meta">
                <div class="todo-card-meta-item">
                  <svg class="todo-card-meta-icon" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
                  </svg>
                  <span class="text-success-600">승인됨</span>
                </div>
                <div v-if="todo.approvedAt" class="todo-card-meta-item">
                  <svg class="todo-card-meta-icon" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd"/>
                  </svg>
                  <span>{{ todo.approvedAt }}</span>
                </div>
              </div>
            </div>
            <div class="todo-card-footer">
              <div class="todo-card-assignee">
                <div class="todo-card-avatar" :style="{ background: todo.assignee.color }">
                  {{ todo.assignee.initials }}
                </div>
                <span class="todo-card-assignee-name">{{ todo.assignee.name }}</span>
              </div>
              <div class="todo-card-tags">
                <span v-for="tag in todo.tags" :key="tag" class="todo-card-tag">{{ tag }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- 거부됨 컬럼 -->
      <div class="todo-column rejected"
           :class="{ 'drop-active': isDraggingOver === 'rejected' }"
           @dragover.prevent="handleDragOver('rejected')"
           @dragleave="handleDragLeave"
           @drop="handleDrop('rejected', $event)">
        <div class="todo-column-header">
          <div class="todo-column-title">
            <div class="todo-column-icon">
              <svg width="18" height="18" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
              </svg>
            </div>
            <span>거부됨</span>
          </div>
          <span class="todo-column-count">{{ filteredRejectedTodos.length }}</span>
        </div>
        <div class="todo-list">
          <div v-if="filteredRejectedTodos.length === 0" class="todo-empty">
            <svg class="todo-empty-icon" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
            </svg>
            <p class="todo-empty-text">거부된 TODO가 없습니다</p>
          </div>
          <div v-for="todo in filteredRejectedTodos" :key="todo.id"
               class="todo-card"
               :class="[`priority-${todo.priority}`, { dragging: draggedTodo?.id === todo.id }]"
               draggable="true"
               @dragstart="handleDragStart(todo, $event)"
               @dragend="handleDragEnd">
            <div class="todo-card-header">
              <h3 class="todo-card-title">{{ todo.title }}</h3>
              <div class="todo-card-actions">
                <button class="todo-card-action-btn" title="대기로 복원" @click="moveToPending(todo.id)">
                  <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M4 2a1 1 0 011 1v2.101a7.002 7.002 0 0111.601 2.566 1 1 0 11-1.885.666A5.002 5.002 0 005.999 7H9a1 1 0 010 2H4a1 1 0 01-1-1V3a1 1 0 011-1zm.008 9.057a1 1 0 011.276.61A5.002 5.002 0 0014.001 13H11a1 1 0 110-2h5a1 1 0 011 1v5a1 1 0 11-2 0v-2.101a7.002 7.002 0 01-11.601-2.566 1 1 0 01.61-1.276z" clip-rule="evenodd"/>
                  </svg>
                </button>
                <button class="todo-card-action-btn danger" title="삭제" @click="deleteTodo(todo.id)">
                  <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clip-rule="evenodd"/>
                  </svg>
                </button>
              </div>
            </div>
            <div class="todo-card-body">
              <p class="todo-card-description">{{ todo.description }}</p>
              <div class="todo-card-meta">
                <div class="todo-card-meta-item">
                  <svg class="todo-card-meta-icon" viewBox="0 0 20 20" fill="currentColor">
                    <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
                  </svg>
                  <span class="text-danger-600">거부됨</span>
                </div>
                <div v-if="todo.rejectedAt" class="todo-card-meta-item">
                  <span class="text-body-xs text-muted">{{ todo.rejectedReason }}</span>
                </div>
              </div>
            </div>
            <div class="todo-card-footer">
              <div class="todo-card-assignee">
                <div class="todo-card-avatar" :style="{ background: todo.assignee.color }">
                  {{ todo.assignee.initials }}
                </div>
                <span class="todo-card-assignee-name">{{ todo.assignee.name }}</span>
              </div>
              <div class="todo-card-tags">
                <span v-for="tag in todo.tags" :key="tag" class="todo-card-tag">{{ tag }}</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 알림 토스트 -->
    <transition name="fade">
      <div v-if="showToast" class="toast-notification" :class="`toast-${toastType}`">
        <svg v-if="toastType === 'success'" width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
        </svg>
        <svg v-else-if="toastType === 'error'" width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd"/>
        </svg>
        <span>{{ toastMessage }}</span>
      </div>
    </transition>
  </div>
</template>

<script setup lang="ts">
/**
 * TODO 승인 관리 화면
 * 드래그 앤 드롭으로 TODO 승인/거부 처리
 *
 * @author 윤성민 책임
 * @since 2026-02-12
 */
import { ref, computed, onMounted } from 'vue'

// TODO 인터페이스
interface Todo {
  id: number
  title: string
  description: string
  priority: 'urgent' | 'high' | 'medium' | 'low'
  status: 'pending' | 'approved' | 'rejected'
  dueDate: string
  estimatedTime: number
  assignee: {
    id: number
    name: string
    initials: string
    color: string
  }
  tags: string[]
  createdAt: string
  approvedAt?: string
  rejectedAt?: string
  rejectedReason?: string
}

// 상태 관리
const todos = ref<Todo[]>([])
const draggedTodo = ref<Todo | null>(null)
const isDraggingOver = ref<string | null>(null)
const searchQuery = ref('')
const selectedPriority = ref('all')
const selectedAssignee = ref<string | number>('all')
const lastUpdateTime = ref('')
const showToast = ref(false)
const toastMessage = ref('')
const toastType = ref<'success' | 'error'>('success')

// 오늘 날짜
const todayDate = computed(() => {
  const today = new Date()
  return today.toLocaleDateString('ko-KR', { year: 'numeric', month: 'long', day: 'numeric' })
})

// 통계
const todayNewCount = ref(8)
const avgProcessTime = ref(12)

// 우선순위 옵션
const priorities = [
  { value: 'all', label: '전체' },
  { value: 'urgent', label: '긴급' },
  { value: 'high', label: '높음' },
  { value: 'medium', label: '보통' },
  { value: 'low', label: '낮음' }
]

// 담당자 옵션
const assignees = [
  { id: 'all', name: '전체' },
  { id: 1, name: '김철수' },
  { id: 2, name: '이영희' },
  { id: 3, name: '박민수' },
  { id: 4, name: '최지은' },
  { id: 5, name: '정우성' }
]

// 샘플 데이터 생성
function generateSampleTodos(): Todo[] {
  const titles = [
    '프로젝트 킥오프 미팅 준비',
    'API 스펙 문서 작성',
    '데이터베이스 스키마 설계',
    'UI/UX 디자인 리뷰',
    '백엔드 API 개발',
    '프론트엔드 컴포넌트 구현',
    '단위 테스트 작성',
    '통합 테스트 시나리오 작성',
    '보안 취약점 점검',
    '성능 최적화 작업',
    '사용자 매뉴얼 작성',
    '배포 환경 구성',
    '코드 리뷰 진행',
    '버그 수정 - 로그인 오류',
    '신규 기능 기획서 검토',
    '고객 피드백 분석',
    '월간 보고서 작성',
    '팀 회고 미팅 준비',
    '인프라 모니터링 설정',
    'CI/CD 파이프라인 개선'
  ]

  const descriptions = [
    '프로젝트 시작을 위한 킥오프 미팅 자료를 준비하고 참석자들에게 공유합니다.',
    'RESTful API 명세서를 작성하고 팀원들과 리뷰를 진행합니다.',
    '프로젝트에 필요한 데이터베이스 테이블 구조를 설계합니다.',
    '디자이너가 제출한 UI/UX 시안을 검토하고 피드백을 제공합니다.',
    '설계된 API 스펙에 맞춰 백엔드 로직을 구현합니다.',
    '재사용 가능한 React 컴포넌트를 개발합니다.',
    '개발한 기능에 대한 단위 테스트를 작성합니다.',
    '주요 사용자 시나리오에 대한 통합 테스트를 설계합니다.',
    '애플리케이션의 보안 취약점을 점검하고 보완합니다.',
    '애플리케이션 로딩 속도와 성능을 개선합니다.',
    '최종 사용자를 위한 상세한 사용 가이드를 작성합니다.',
    '프로덕션 배포를 위한 서버 환경을 구성합니다.',
    '팀원들의 코드를 리뷰하고 개선사항을 제안합니다.',
    '사용자 로그인 시 발생하는 오류를 분석하고 수정합니다.',
    '다음 스프린트에 추가할 신규 기능을 검토합니다.',
    '고객 VOC를 수집하고 우선순위를 정리합니다.',
    '이번 달 프로젝트 진행 상황을 정리하여 보고서를 작성합니다.',
    '스프린트 회고를 위한 자료를 준비하고 미팅을 진행합니다.',
    '서버 상태를 실시간으로 모니터링할 수 있도록 설정합니다.',
    '자동 빌드 및 배포 프로세스를 개선합니다.'
  ]

  const priorities: ('urgent' | 'high' | 'medium' | 'low')[] = ['urgent', 'high', 'medium', 'low']
  const statuses: ('pending' | 'approved' | 'rejected')[] = ['pending', 'pending', 'pending', 'approved', 'rejected']
  const tags = [
    ['개발', 'Backend'],
    ['개발', 'Frontend'],
    ['디자인', 'UI/UX'],
    ['테스트', 'QA'],
    ['문서', 'Documentation'],
    ['회의', 'Meeting'],
    ['긴급', 'Hotfix'],
    ['기획', 'Planning'],
    ['인프라', 'DevOps']
  ]

  const assigneeList = [
    { id: 1, name: '김철수', initials: '김철', color: 'linear-gradient(135deg, #3b82f6 0%, #2563eb 100%)' },
    { id: 2, name: '이영희', initials: '이영', color: 'linear-gradient(135deg, #10b981 0%, #059669 100%)' },
    { id: 3, name: '박민수', initials: '박민', color: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)' },
    { id: 4, name: '최지은', initials: '최지', color: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)' },
    { id: 5, name: '정우성', initials: '정우', color: 'linear-gradient(135deg, #06b6d4 0%, #0891b2 100%)' }
  ]

  const sampleTodos: Todo[] = []

  for (let i = 0; i < 20; i++) {
    const status = statuses[Math.floor(Math.random() * statuses.length)]
    const priority = priorities[Math.floor(Math.random() * priorities.length)]
    const assignee = assigneeList[Math.floor(Math.random() * assigneeList.length)]
    const tagSet = tags[Math.floor(Math.random() * tags.length)]

    // undefined 체크
    if (!status || !priority || !assignee || !tagSet) continue

    const todo: Todo = {
      id: i + 1,
      title: titles[i] || 'TODO 항목',
      description: descriptions[i] || '설명이 없습니다.',
      priority,
      status,
      dueDate: getRandomDate(),
      estimatedTime: Math.floor(Math.random() * 8) + 1,
      assignee,
      tags: tagSet,
      createdAt: getRandomCreatedDate()
    }

    if (status === 'approved') {
      todo.approvedAt = getRandomApprovedDate()
    } else if (status === 'rejected') {
      todo.rejectedAt = getRandomApprovedDate()
      todo.rejectedReason = '요구사항 불명확'
    }

    sampleTodos.push(todo)
  }

  return sampleTodos
}

// 랜덤 날짜 생성
function getRandomDate(): string {
  const today = new Date()
  const futureDate = new Date(today.getTime() + Math.random() * 7 * 24 * 60 * 60 * 1000)
  return futureDate.toLocaleDateString('ko-KR', { month: 'short', day: 'numeric' })
}

function getRandomCreatedDate(): string {
  const today = new Date()
  const pastDate = new Date(today.getTime() - Math.random() * 3 * 24 * 60 * 60 * 1000)
  return pastDate.toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit' })
}

function getRandomApprovedDate(): string {
  const now = new Date()
  const recentDate = new Date(now.getTime() - Math.random() * 6 * 60 * 60 * 1000)
  return recentDate.toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit' })
}

// 필터링된 TODO 목록
const pendingTodos = computed(() => todos.value.filter(t => t.status === 'pending'))
const approvedTodos = computed(() => todos.value.filter(t => t.status === 'approved'))
const rejectedTodos = computed(() => todos.value.filter(t => t.status === 'rejected'))

const filteredPendingTodos = computed(() => filterTodos(pendingTodos.value))
const filteredApprovedTodos = computed(() => filterTodos(approvedTodos.value))
const filteredRejectedTodos = computed(() => filterTodos(rejectedTodos.value))

function filterTodos(todoList: Todo[]): Todo[] {
  return todoList.filter(todo => {
    const matchPriority = selectedPriority.value === 'all' || todo.priority === selectedPriority.value
    const matchAssignee = selectedAssignee.value === 'all' || todo.assignee.id.toString() === selectedAssignee.value
    const matchSearch = !searchQuery.value ||
      todo.title.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
      todo.description.toLowerCase().includes(searchQuery.value.toLowerCase())

    return matchPriority && matchAssignee && matchSearch
  })
}

// 승인율 계산
const approvalRate = computed(() => {
  const total = approvedTodos.value.length + rejectedTodos.value.length
  if (total === 0) return 0
  return Math.round((approvedTodos.value.length / total) * 100)
})

// 드래그 앤 드롭 핸들러
function handleDragStart(todo: Todo, event: DragEvent) {
  draggedTodo.value = todo
  if (event.dataTransfer) {
    event.dataTransfer.effectAllowed = 'move'
    event.dataTransfer.setData('text/plain', todo.id.toString())
  }
}

function handleDragEnd() {
  draggedTodo.value = null
  isDraggingOver.value = null
}

function handleDragOver(status: string) {
  isDraggingOver.value = status
}

function handleDragLeave() {
  isDraggingOver.value = null
}

function handleDrop(status: string, event: DragEvent) {
  event.preventDefault()
  isDraggingOver.value = null

  if (!draggedTodo.value) return

  const todo = draggedTodo.value
  const oldStatus = todo.status

  if (oldStatus === status) {
    draggedTodo.value = null
    return
  }

  // 상태 변경
  todo.status = status as 'pending' | 'approved' | 'rejected'

  if (status === 'approved') {
    todo.approvedAt = new Date().toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit' })
    showToastNotification('승인되었습니다', 'success')
  } else if (status === 'rejected') {
    todo.rejectedAt = new Date().toLocaleTimeString('ko-KR', { hour: '2-digit', minute: '2-digit' })
    todo.rejectedReason = '재검토 필요'
    showToastNotification('거부되었습니다', 'error')
  } else {
    todo.approvedAt = undefined
    todo.rejectedAt = undefined
    todo.rejectedReason = undefined
    showToastNotification('대기 상태로 변경되었습니다', 'success')
  }

  draggedTodo.value = null
}

// 우선순위 라벨
function getPriorityLabel(priority: string): string {
  const labels: Record<string, string> = {
    urgent: '긴급',
    high: '높음',
    medium: '보통',
    low: '낮음'
  }
  return labels[priority] || priority
}

function getPriorityBadgeClass(priority: string): string {
  const classes: Record<string, string> = {
    urgent: 'danger',
    high: 'warning',
    medium: 'primary',
    low: 'gray'
  }
  return classes[priority] || 'gray'
}

// TODO 액션
function editTodo(todo: Todo) {
  console.log('Edit TODO:', todo)
  showToastNotification('수정 기능은 준비 중입니다', 'success')
}

function deleteTodo(id: number) {
  if (confirm('정말 삭제하시겠습니까?')) {
    todos.value = todos.value.filter(t => t.id !== id)
    showToastNotification('삭제되었습니다', 'success')
  }
}

function moveToPending(id: number) {
  const todo = todos.value.find(t => t.id === id)
  if (todo) {
    todo.status = 'pending'
    todo.rejectedAt = undefined
    todo.rejectedReason = undefined
    showToastNotification('대기 상태로 복원되었습니다', 'success')
  }
}

function showAddTodoModal() {
  showToastNotification('TODO 추가 기능은 준비 중입니다', 'success')
}

function refreshTodos() {
  updateTime()
  showToastNotification('새로고침되었습니다', 'success')
}

// 토스트 알림
function showToastNotification(message: string, type: 'success' | 'error') {
  toastMessage.value = message
  toastType.value = type
  showToast.value = true

  setTimeout(() => {
    showToast.value = false
  }, 3000)
}

// 시간 업데이트
function updateTime() {
  const now = new Date()
  lastUpdateTime.value = now.toLocaleTimeString('ko-KR', {
    hour: '2-digit',
    minute: '2-digit'
  })
}

// 초기화
onMounted(() => {
  todos.value = generateSampleTodos()
  updateTime()
  setInterval(updateTime, 60000)
})
</script>

<style scoped>
/* 토스트 알림 */
.toast-notification {
  position: fixed;
  bottom: 2rem;
  right: 2rem;
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem 1.5rem;
  background-color: white;
  border-radius: 12px;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.15);
  z-index: 9999;
  font-size: 0.875rem;
  font-weight: 500;
  min-width: 280px;
}

.toast-success {
  border-left: 4px solid var(--color-success-600);
  color: var(--color-success-800);
}

.toast-success svg {
  color: var(--color-success-600);
  flex-shrink: 0;
}

.toast-error {
  border-left: 4px solid var(--color-danger-600);
  color: var(--color-danger-800);
}

.toast-error svg {
  color: var(--color-danger-600);
  flex-shrink: 0;
}

/* 페이드 트랜지션 */
.fade-enter-active, .fade-leave-active {
  transition: all 0.3s ease;
}

.fade-enter-from {
  opacity: 0;
  transform: translateY(1rem);
}

.fade-leave-to {
  opacity: 0;
  transform: translateX(1rem);
}
</style>



