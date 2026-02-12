<template>
  <div class="page-container">
    <!-- 페이지 헤더 -->
    <div class="page-header">
      <div class="page-title-wrapper">
        <h1 class="text-h2">프로젝트 대시보드</h1>
        <span class="badge badge-primary ml-3">실시간</span>
      </div>
      <div class="flex gap-2 items-center">
        <button class="btn btn-ghost btn-icon" title="새로고침" @click="refreshData">
          <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M4 2a1 1 0 011 1v2.101a7.002 7.002 0 0111.601 2.566 1 1 0 11-1.885.666A5.002 5.002 0 005.999 7H9a1 1 0 010 2H4a1 1 0 01-1-1V3a1 1 0 011-1zm.008 9.057a1 1 0 011.276.61A5.002 5.002 0 0014.001 13H11a1 1 0 110-2h5a1 1 0 011 1v5a1 1 0 11-2 0v-2.101a7.002 7.002 0 01-11.601-2.566 1 1 0 01.61-1.276z" clip-rule="evenodd"/>
          </svg>
        </button>
        <div class="dropdown">
          <button class="btn btn-ghost dropdown-toggle">
            <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M3 3a1 1 0 000 2v8a2 2 0 002 2h2.586l-1.293 1.293a1 1 0 101.414 1.414L10 15.414l2.293 2.293a1 1 0 001.414-1.414L12.414 15H15a2 2 0 002-2V5a1 1 0 100-2H3zm11.707 4.707a1 1 0 00-1.414-1.414L10 9.586 8.707 8.293a1 1 0 00-1.414 0l-2 2a1 1 0 101.414 1.414L8 10.414l1.293 1.293a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
            </svg>
            내보내기
          </button>
        </div>
        <button class="btn btn-primary">
          <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd"/>
          </svg>
          새 프로젝트
        </button>
      </div>
    </div>
    <div class="page-description mb-6">
      <svg class="page-description-icon" viewBox="0 0 20 20" fill="currentColor">
        <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
      </svg>
      <span><strong>실시간 프로젝트 현황</strong>을 한눈에 확인하고 <strong>효율적으로 관리</strong>하세요 <span class="page-description-divider">•</span> <span class="page-description-time">최종 업데이트: {{ lastUpdateTime }}</span></span>
    </div>

    <!-- 주요 메트릭 카드 -->
    <div class="grid grid-cols-4 md:grid-cols-2 gap-6 mb-8">
      <div v-for="(metric, index) in metrics" :key="index"
           class="metric-card animate-stagger"
           :class="metric.colorClass"
           :style="{ animationDelay: `${index * 0.1}s` }">
        <div class="stat-widget-header">
          <span class="stat-widget-title">{{ metric.label }}</span>
        </div>
        <div class="stat-widget-value animate-count-up">{{ metric.value }}</div>
        <div v-if="metric.change" class="stat-widget-change" :class="metric.change > 0 ? 'positive' : 'negative'">
          <svg width="14" height="14" viewBox="0 0 20 20" fill="currentColor">
            <path v-if="metric.change > 0" fill-rule="evenodd" d="M5.293 7.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 5.414V17a1 1 0 11-2 0V5.414L6.707 7.707a1 1 0 01-1.414 0z" clip-rule="evenodd"/>
            <path v-else fill-rule="evenodd" d="M14.707 12.293a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 111.414-1.414L9 14.586V3a1 1 0 012 0v11.586l2.293-2.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
          </svg>
          {{ Math.abs(metric.change) }}% {{ metric.changeLabel }}
        </div>
      </div>
    </div>

    <!-- 차트 및 활동 -->
    <div class="grid grid-cols-12 md:grid-cols-1 gap-6 mb-8">
      <!-- 메인 차트 -->
      <div class="col-span-8">
        <div class="widget-card">
          <div class="widget-card-header">
            <div>
              <div class="widget-card-title">프로젝트 진행 현황</div>
              <div class="text-body-xs text-muted mt-1">최근 30일간의 진행 추이</div>
            </div>
            <div class="flex gap-2">
              <button v-for="period in periods" :key="period.value"
                      class="btn btn-sm"
                      :class="selectedPeriod === period.value ? 'btn-primary' : 'btn-ghost'"
                      @click="selectedPeriod = period.value">
                {{ period.label }}
              </button>
            </div>
          </div>
          <div class="widget-card-body">
            <div ref="mainChartRef" style="height: 320px;" class="animate-chart-load"></div>
          </div>
        </div>
      </div>

      <!-- 최근 활동 -->
      <div class="col-span-8">
        <div class="widget-card">
          <div class="widget-card-header">
            <div class="widget-card-title">최근 활동</div>
            <span class="badge badge-sm badge-primary">{{ activities.length }}</span>
          </div>
          <div class="widget-card-body p-0">
            <div v-for="(activity, index) in activities" :key="index" class="list-card-item">
              <div class="flex items-start gap-3">
                <div class="flex-shrink-0">
                  <div class="w-10 h-10 rounded-full flex items-center justify-center"
                       :style="{ background: activity.color }">
                    <svg width="20" height="20" viewBox="0 0 20 20" fill="white" v-html="activity.icon"></svg>
                  </div>
                </div>
                <div class="flex-1 min-w-0">
                  <div class="text-body-sm font-semibold text-neutral-900 mb-1">{{ activity.title }}</div>
                  <div class="text-body-xs text-muted mb-2">{{ activity.description }}</div>
                  <div class="flex items-center gap-2 text-body-xs text-muted">
                    <svg width="14" height="14" viewBox="0 0 20 20" fill="currentColor">
                      <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-12a1 1 0 10-2 0v4a1 1 0 00.293.707l2.828 2.829a1 1 0 101.415-1.415L11 9.586V6z" clip-rule="evenodd"/>
                    </svg>
                    {{ activity.time }}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 프로젝트 상태 및 팀 현황 -->
    <div class="grid grid-cols-2 md:grid-cols-1 gap-6 mb-8">
      <!-- 프로젝트 상태 분포 -->
      <div class="widget-card">
        <div class="widget-card-header">
          <div class="widget-card-title">프로젝트 상태 분포</div>
        </div>
        <div class="widget-card-body">
          <div ref="statusChartRef" style="height: 280px;" class="animate-chart-load"></div>
        </div>
      </div>

      <!-- 팀별 진행률 -->
      <div class="widget-card">
        <div class="widget-card-header">
          <div class="widget-card-title">팀별 진행률</div>
        </div>
        <div class="widget-card-body">
          <div ref="teamChartRef" style="height: 280px;" class="animate-chart-load"></div>
        </div>
      </div>
    </div>

    <!-- 프로젝트 목록 -->
    <div class="widget-card">
      <div class="widget-card-header">
        <div class="widget-card-title">진행 중인 프로젝트</div>
        <div class="flex gap-2 items-center">
          <div class="form-group mb-0">
            <input type="search"
                   class="form-input form-input-sm"
                   placeholder="프로젝트 검색..."
                   v-model="searchQuery"
                   style="min-width: 200px;">
          </div>
          <button class="btn btn-sm btn-ghost">
            <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
              <path d="M3 3a1 1 0 000 2h11a1 1 0 100-2H3zM3 7a1 1 0 000 2h5a1 1 0 000-2H3zM3 11a1 1 0 100 2h4a1 1 0 100-2H3zM13 16a1 1 0 102 0v-5.586l1.293 1.293a1 1 0 001.414-1.414l-3-3a1 1 0 00-1.414 0l-3 3a1 1 0 101.414 1.414L13 10.414V16z"/>
            </svg>
            필터
          </button>
        </div>
      </div>
      <div class="widget-card-body p-0">
        <div class="table-container">
          <table class="table table-hover">
            <thead>
              <tr>
                <th><input type="checkbox" class="form-checkbox"></th>
                <th>프로젝트명</th>
                <th>담당자</th>
                <th>진행률</th>
                <th>상태</th>
                <th>마감일</th>
                <th class="text-center">작업</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="project in filteredProjects" :key="project.id">
                <td><input type="checkbox" class="form-checkbox"></td>
                <td>
                  <div class="flex items-center gap-3">
                    <div class="avatar avatar-sm" :style="{ background: project.avatarColor }">
                      {{ project.name.charAt(0) }}
                    </div>
                    <div>
                      <div class="font-semibold text-neutral-900">{{ project.name }}</div>
                      <div class="text-body-xs text-muted">{{ project.category }}</div>
                    </div>
                  </div>
                </td>
                <td>
                  <div class="flex items-center gap-2">
                    <div class="avatar avatar-sm" :style="{ background: project.managerColor }">
                      {{ project.manager.charAt(0) }}
                    </div>
                    <span class="text-body-sm">{{ project.manager }}</span>
                  </div>
                </td>
                <td>
                  <div class="flex items-center gap-3">
                    <div class="progress" style="width: 100px;">
                      <div class="progress-bar" :class="`progress-bar-${project.statusType}`"
                           :style="{ width: project.progress + '%' }"></div>
                    </div>
                    <span class="text-body-sm font-semibold">{{ project.progress }}%</span>
                  </div>
                </td>
                <td>
                  <span class="badge badge-dot" :class="`badge-${project.statusType}`">{{ project.status }}</span>
                </td>
                <td>
                  <div class="flex items-center gap-2 text-body-sm">
                    <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor" class="text-muted">
                      <path fill-rule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clip-rule="evenodd"/>
                    </svg>
                    {{ project.deadline }}
                  </div>
                </td>
                <td>
                  <div class="flex gap-1 justify-center">
                    <button class="btn btn-sm btn-ghost btn-icon" title="상세보기">
                      <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
                        <path d="M10 12a2 2 0 100-4 2 2 0 000 4z"/>
                        <path fill-rule="evenodd" d="M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z" clip-rule="evenodd"/>
                      </svg>
                    </button>
                    <button class="btn btn-sm btn-ghost btn-icon" title="수정">
                      <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
                        <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z"/>
                      </svg>
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- 알림 -->
    <div class="mt-6">
      <div class="info-card">
        <svg class="info-card-icon" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd"/>
        </svg>
        <div class="info-card-content">
          <strong>알림:</strong> 3개의 프로젝트가 마감일이 임박했습니다. 진행 상황을 확인해주세요.
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
/**
 * PMS 대시보드 메인 화면
 *
 * @author 윤성민 책임
 * @since 2026-02-11
 */
import { ref, computed, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'

// Refs
const mainChartRef = ref<HTMLDivElement>()
const statusChartRef = ref<HTMLDivElement>()
const teamChartRef = ref<HTMLDivElement>()
const searchQuery = ref('')
const selectedPeriod = ref('monthly')
const lastUpdateTime = ref('')

// 기간 선택
const periods = [
  { value: 'daily', label: '일간' },
  { value: 'monthly', label: '월간' },
  { value: 'yearly', label: '연간' }
]

// 주요 메트릭
const metrics = ref([
  {
    label: '진행 중인 프로젝트',
    value: '24',
    change: 12,
    changeLabel: '전월 대비',
    colorClass: 'metric-card-primary'
  },
  {
    label: '완료된 작업',
    value: '1,247',
    change: 8,
    changeLabel: '전월 대비',
    colorClass: 'metric-card-success'
  },
  {
    label: '팀 멤버',
    value: '48',
    change: 0,
    changeLabel: '변동 없음',
    colorClass: 'metric-card-purple'
  },
  {
    label: '지연된 작업',
    value: '3',
    change: -5,
    changeLabel: '지난주 대비',
    colorClass: 'metric-card-warning'
  }
])

// 최근 활동
const activities = ref([
  {
    title: '새 프로젝트 생성',
    description: 'AI 챗봇 시스템 개발 프로젝트가 시작되었습니다',
    time: '5분 전',
    color: 'linear-gradient(135deg, #3b82f6 0%, #2563eb 100%)',
    icon: '<path fill-rule="evenodd" d="M10 3a1 1 0 011 1v5h5a1 1 0 110 2h-5v5a1 1 0 11-2 0v-5H4a1 1 0 110-2h5V4a1 1 0 011-1z" clip-rule="evenodd"/>'
  },
  {
    title: '작업 완료',
    description: 'UI 디자인 검토 작업이 완료되었습니다',
    time: '1시간 전',
    color: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
    icon: '<path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>'
  },
  {
    title: '팀원 배정',
    description: '김철수님이 프로젝트 A에 배정되었습니다',
    time: '3시간 전',
    color: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)',
    icon: '<path d="M8 9a3 3 0 100-6 3 3 0 000 6zM8 11a6 6 0 016 6H2a6 6 0 016-6zM16 7a1 1 0 10-2 0v1h-1a1 1 0 100 2h1v1a1 1 0 102 0v-1h1a1 1 0 100-2h-1V7z"/>'
  },
  {
    title: '마일스톤 달성',
    description: '모바일 앱 개발 1단계가 완료되었습니다',
    time: '5시간 전',
    color: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)',
    icon: '<path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z"/>'
  }
])

// 프로젝트 목록
const projects = ref([
  {
    id: 1,
    name: '고객 포털 개발',
    category: '웹 애플리케이션',
    manager: '김철수',
    progress: 75,
    status: '진행중',
    statusType: 'success',
    deadline: '2026-03-15',
    avatarColor: 'linear-gradient(135deg, #3b82f6 0%, #2563eb 100%)',
    managerColor: 'linear-gradient(135deg, #10b981 0%, #059669 100%)'
  },
  {
    id: 2,
    name: '모바일 앱 리뉴얼',
    category: 'iOS & Android',
    manager: '이영희',
    progress: 45,
    status: '검토중',
    statusType: 'warning',
    deadline: '2026-04-01',
    avatarColor: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)',
    managerColor: 'linear-gradient(135deg, #ec4899 0%, #db2777 100%)'
  },
  {
    id: 3,
    name: 'API 서버 구축',
    category: '백엔드',
    manager: '박민수',
    progress: 30,
    status: '시작',
    statusType: 'info',
    deadline: '2026-05-20',
    avatarColor: 'linear-gradient(135deg, #06b6d4 0%, #0891b2 100%)',
    managerColor: 'linear-gradient(135deg, #f59e0b 0%, #d97706 100%)'
  },
  {
    id: 4,
    name: 'AI 챗봇 시스템',
    category: '머신러닝',
    manager: '최지은',
    progress: 90,
    status: '완료 임박',
    statusType: 'success',
    deadline: '2026-02-28',
    avatarColor: 'linear-gradient(135deg, #10b981 0%, #059669 100%)',
    managerColor: 'linear-gradient(135deg, #3b82f6 0%, #2563eb 100%)'
  }
])

const filteredProjects = computed(() => {
  if (!searchQuery.value) return projects.value

  return projects.value.filter(project =>
    project.name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
    project.category.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
    project.manager.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
})

let mainChart: echarts.ECharts | null = null
let statusChart: echarts.ECharts | null = null
let teamChart: echarts.ECharts | null = null

// 메인 차트 초기화
function initMainChart() {
  if (!mainChartRef.value) return

  mainChart = echarts.init(mainChartRef.value)

  const option = {
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'shadow'
      }
    },
    legend: {
      data: ['완료', '진행중', '대기']
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: ['1주', '2주', '3주', '4주']
    },
    yAxis: {
      type: 'value'
    },
    series: [
      {
        name: '완료',
        type: 'bar',
        stack: 'total',
        data: [320, 332, 301, 334],
        itemStyle: {
          color: '#10b981'
        }
      },
      {
        name: '진행중',
        type: 'bar',
        stack: 'total',
        data: [120, 132, 101, 134],
        itemStyle: {
          color: '#3b82f6'
        }
      },
      {
        name: '대기',
        type: 'bar',
        stack: 'total',
        data: [20, 12, 11, 14],
        itemStyle: {
          color: '#f59e0b'
        }
      }
    ]
  }

  mainChart.setOption(option)
}

// 상태 차트 초기화
function initStatusChart() {
  if (!statusChartRef.value) return

  statusChart = echarts.init(statusChartRef.value)

  const option = {
    tooltip: {
      trigger: 'item'
    },
    legend: {
      orient: 'vertical',
      left: 'left'
    },
    series: [
      {
        name: '프로젝트 상태',
        type: 'pie',
        radius: ['40%', '70%'],
        avoidLabelOverlap: false,
        itemStyle: {
          borderRadius: 10,
          borderColor: '#fff',
          borderWidth: 2
        },
        data: [
          { value: 24, name: '진행중', itemStyle: { color: '#3b82f6' } },
          { value: 15, name: '완료', itemStyle: { color: '#10b981' } },
          { value: 8, name: '대기', itemStyle: { color: '#f59e0b' } },
          { value: 3, name: '지연', itemStyle: { color: '#ef4444' } }
        ]
      }
    ]
  }

  statusChart.setOption(option)
}

// 팀 차트 초기화
function initTeamChart() {
  if (!teamChartRef.value) return

  teamChart = echarts.init(teamChartRef.value)

  const option = {
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'shadow'
      }
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true
    },
    xAxis: {
      type: 'value',
      max: 100
    },
    yAxis: {
      type: 'category',
      data: ['개발팀', '디자인팀', '기획팀', '마케팅팀']
    },
    series: [
      {
        name: '진행률',
        type: 'bar',
        data: [
          { value: 85, itemStyle: { color: '#10b981' } },
          { value: 72, itemStyle: { color: '#3b82f6' } },
          { value: 65, itemStyle: { color: '#8b5cf6' } },
          { value: 58, itemStyle: { color: '#f59e0b' } }
        ],
        label: {
          show: true,
          position: 'right',
          formatter: '{c}%'
        }
      }
    ]
  }

  teamChart.setOption(option)
}

function refreshData() {
  console.log('데이터 새로고침')
  if (mainChart) initMainChart()
  if (statusChart) initStatusChart()
  if (teamChart) initTeamChart()
}

function updateTime() {
  const now = new Date()
  lastUpdateTime.value = now.toLocaleTimeString('ko-KR', {
    hour: '2-digit',
    minute: '2-digit'
  })
}

onMounted(() => {
  updateTime()
  setInterval(updateTime, 60000)

  setTimeout(() => {
    initMainChart()
    initStatusChart()
    initTeamChart()
  }, 100)

  window.addEventListener('resize', () => {
    mainChart?.resize()
    statusChart?.resize()
    teamChart?.resize()
  })
})

onUnmounted(() => {
  mainChart?.dispose()
  statusChart?.dispose()
  teamChart?.dispose()
})
</script>

