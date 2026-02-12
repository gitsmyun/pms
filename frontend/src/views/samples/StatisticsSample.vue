<template>
  <div class="page-container">
    <!-- 페이지 헤더 -->
    <div class="page-header">
      <div class="page-title-wrapper">
        <h1 class="text-h2">프로젝트 진척 통계</h1>
        <span class="badge badge-pill badge-info ml-3">실시간 분석</span>
      </div>
      <div class="flex gap-2 items-center">
        <button class="btn btn-ghost btn-icon" title="새로고침" @click="refreshAllCharts">
          <svg width="20" height="20" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M4 2a1 1 0 011 1v2.101a7.002 7.002 0 0111.601 2.566 1 1 0 11-1.885.666A5.002 5.002 0 005.999 7H9a1 1 0 010 2H4a1 1 0 01-1-1V3a1 1 0 011-1zm.008 9.057a1 1 0 011.276.61A5.002 5.002 0 0014.001 13H11a1 1 0 110-2h5a1 1 0 011 1v5a1 1 0 11-2 0v-2.101a7.002 7.002 0 01-11.601-2.566 1 1 0 01.61-1.276z" clip-rule="evenodd"/>
          </svg>
        </button>
        <div class="chart-filters">
          <button v-for="period in periods" :key="period.value"
                  class="chart-filter-btn"
                  :class="{ active: selectedPeriod === period.value }"
                  @click="selectedPeriod = period.value">
            {{ period.label }}
          </button>
        </div>
        <button class="btn btn-outline-primary">
          <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M3 17a1 1 0 011-1h12a1 1 0 110 2H4a1 1 0 01-1-1zm3.293-7.707a1 1 0 011.414 0L9 10.586V3a1 1 0 112 0v7.586l1.293-1.293a1 1 0 111.414 1.414l-3 3a1 1 0 01-1.414 0l-3-3a1 1 0 010-1.414z" clip-rule="evenodd"/>
          </svg>
          리포트 다운로드
        </button>
      </div>
    </div>
    <div class="page-description mb-6">
      <svg class="page-description-icon" viewBox="0 0 20 20" fill="currentColor">
        <path fill-rule="evenodd" d="M3 3a1 1 0 000 2v8a2 2 0 002 2h2.586l-1.293 1.293a1 1 0 101.414 1.414L10 15.414l2.293 2.293a1 1 0 001.414-1.414L12.414 15H15a2 2 0 002-2V5a1 1 0 100-2H3zm11.707 4.707a1 1 0 00-1.414-1.414L10 9.586 8.707 8.293a1 1 0 00-1.414 0l-2 2a1 1 0 101.414 1.414L8 10.414l1.293 1.293a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
      </svg>
      <span><strong>프로젝트 진행 상황</strong>을 <strong>다양한 시각적 지표</strong>로 분석하고 <strong>인사이트</strong>를 얻으세요 <span class="page-description-divider">•</span> <span class="page-description-time">최종 업데이트: {{ lastUpdateTime }}</span></span>
    </div>

    <!-- KPI 메트릭 카드 -->
    <div class="grid grid-cols-4 md:grid-cols-2 gap-6 mb-8">
      <div v-for="(kpi, index) in kpiMetrics" :key="index"
           class="metric-card animate-stagger"
           :class="kpi.colorClass"
           :style="{ animationDelay: `${index * 0.1}s` }">
        <div class="stat-widget-header">
          <span class="stat-widget-title">{{ kpi.label }}</span>
        </div>
        <div class="stat-widget-value animate-count-up">{{ kpi.value }}</div>
        <div class="stat-widget-change" :class="kpi.trend === 'up' ? 'positive' : kpi.trend === 'down' ? 'negative' : ''">
          <svg v-if="kpi.trend !== 'neutral'" width="14" height="14" viewBox="0 0 20 20" fill="currentColor">
            <path v-if="kpi.trend === 'up'" fill-rule="evenodd" d="M5.293 7.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 5.414V17a1 1 0 11-2 0V5.414L6.707 7.707a1 1 0 01-1.414 0z" clip-rule="evenodd"/>
            <path v-else fill-rule="evenodd" d="M14.707 12.293a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 111.414-1.414L9 14.586V3a1 1 0 012 0v11.586l2.293-2.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
          </svg>
          {{ kpi.changeText }}
        </div>
        <div class="stat-widget-chart" :ref="(el) => setMiniChartRef(el, index)"></div>
      </div>
    </div>

    <!-- 메인 차트 그리드 -->
    <div class="grid grid-cols-12 md:grid-cols-1 gap-6 mb-8">
      <!-- 프로젝트 진행 추이 (라인 차트) -->
      <div class="col-span-8">
        <div class="chart-container" style="height: auto;">
          <div class="chart-header">
            <div>
              <div class="chart-title">프로젝트 진행 추이</div>
              <p class="chart-subtitle">최근 12개월 간의 프로젝트 완료율 및 작업 추이</p>
            </div>
            <div class="chart-legend">
              <div class="chart-legend-item">
                <span class="chart-legend-dot" style="background-color: #3b82f6;"></span>
                완료율
              </div>
              <div class="chart-legend-item">
                <span class="chart-legend-dot" style="background-color: #10b981;"></span>
                작업량
              </div>
            </div>
          </div>
          <div ref="progressTrendChartRef" style="width: 100%; height: 350px;" class="animate-chart-load"></div>
        </div>
      </div>

      <!-- 팀 성과 비교 (레이더 차트) -->
      <div class="col-span-4">
        <div class="chart-container chart-container-md" style="height: auto;">
          <div class="chart-header">
            <div class="chart-title">팀 성과 지표</div>
          </div>
          <div ref="teamRadarChartRef" style="width: 100%; height: 320px;" class="animate-chart-load"></div>
        </div>
      </div>
    </div>

    <!-- 차트 그리드 2열 -->
    <div class="grid grid-cols-2 md:grid-cols-1 gap-6 mb-8">
      <!-- 프로젝트 상태 분포 (도넛 차트) -->
      <div class="chart-container" style="height: auto;">
        <div class="chart-header">
          <div class="chart-title">프로젝트 상태 분포</div>
          <div class="chart-toolbar">
            <button class="chart-toolbar-btn" title="전체화면">
              <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
                <path d="M3 4a1 1 0 011-1h4a1 1 0 010 2H6.414l2.293 2.293a1 1 0 11-1.414 1.414L5 6.414V8a1 1 0 01-2 0V4zm9 1a1 1 0 010-2h4a1 1 0 011 1v4a1 1 0 01-2 0V6.414l-2.293 2.293a1 1 0 11-1.414-1.414L13.586 5H12zm-9 7a1 1 0 012 0v1.586l2.293-2.293a1 1 0 111.414 1.414L6.414 15H8a1 1 0 010 2H4a1 1 0 01-1-1v-4zm13-1a1 1 0 011 1v4a1 1 0 01-1 1h-4a1 1 0 010-2h1.586l-2.293-2.293a1 1 0 111.414-1.414L15 13.586V12a1 1 0 011-1z"/>
              </svg>
            </button>
          </div>
        </div>
        <div ref="statusDonutChartRef" style="width: 100%; height: 320px;" class="animate-chart-load"></div>
      </div>

      <!-- 우선순위별 작업 분포 (파이 차트) -->
      <div class="chart-container" style="height: auto;">
        <div class="chart-header">
          <div class="chart-title">우선순위별 작업 분포</div>
          <span class="badge badge-sm badge-solid-primary">{{ totalTasks }} Tasks</span>
        </div>
        <div ref="priorityPieChartRef" style="width: 100%; height: 320px;" class="animate-chart-load"></div>
      </div>
    </div>

    <!-- 3열 차트 그리드 -->
    <div class="grid grid-cols-3 lg:grid-cols-2 md:grid-cols-1 gap-6 mb-8">
      <!-- 월별 작업 완료 추이 (바 차트) -->
      <div class="chart-container chart-container-md" style="height: auto;">
        <div class="chart-header">
          <div class="chart-title">월별 작업 완료</div>
        </div>
        <div ref="monthlyBarChartRef" style="width: 100%; height: 280px;" class="animate-chart-load"></div>
      </div>

      <!-- 팀별 진행률 (게이지 차트) -->
      <div class="chart-container chart-container-md" style="height: auto;">
        <div class="chart-header">
          <div class="chart-title">전체 진행률</div>
        </div>
        <div ref="gaugeChartRef" style="width: 100%; height: 280px;" class="animate-chart-load"></div>
      </div>

      <!-- 버그 현황 (펀널 차트) -->
      <div class="chart-container chart-container-md" style="height: auto;">
        <div class="chart-header">
          <div class="chart-title">이슈 처리 현황</div>
        </div>
        <div ref="funnelChartRef" style="width: 100%; height: 280px;" class="animate-chart-load"></div>
      </div>
    </div>

    <!-- 히트맵 & 산점도 -->
    <div class="grid grid-cols-2 md:grid-cols-1 gap-6 mb-8">
      <!-- 작업 시간 히트맵 -->
      <div class="chart-container" style="height: auto;">
        <div class="chart-header">
          <div class="chart-title">주간 작업 시간 분포</div>
          <p class="chart-subtitle">시간대별 팀 활동 히트맵</p>
        </div>
        <div ref="heatmapChartRef" style="width: 100%; height: 320px;" class="animate-chart-load"></div>
      </div>

      <!-- 프로젝트 난이도 vs 진행률 (산점도) -->
      <div class="chart-container" style="height: auto;">
        <div class="chart-header">
          <div class="chart-title">프로젝트 난이도 vs 진행률</div>
          <p class="chart-subtitle">복잡도와 진행 상황 상관관계</p>
        </div>
        <div ref="scatterChartRef" style="width: 100%; height: 320px;" class="animate-chart-load"></div>
      </div>
    </div>

    <!-- 스택 영역 차트 & 트리맵 -->
    <div class="grid grid-cols-12 md:grid-cols-1 gap-6 mb-8">
      <!-- 스택 영역 차트 - 작업 유형별 추이 -->
      <div class="col-span-7">
        <div class="chart-container" style="height: auto;">
          <div class="chart-header">
            <div class="chart-title">작업 유형별 진행 추이</div>
            <p class="chart-subtitle">개발/디자인/테스트 작업량 변화</p>
          </div>
          <div ref="stackedAreaChartRef" style="width: 100%; height: 320px;" class="animate-chart-load"></div>
        </div>
      </div>

      <!-- 트리맵 - 프로젝트 리소스 분포 -->
      <div class="col-span-5">
        <div class="chart-container" style="height: auto;">
          <div class="chart-header">
            <div class="chart-title">리소스 할당 현황</div>
          </div>
          <div ref="treemapChartRef" style="width: 100%; height: 320px;" class="animate-chart-load"></div>
        </div>
      </div>
    </div>

    <!-- 통계 테이블 -->
    <div class="widget-card mb-8">
      <div class="widget-card-header">
        <div class="widget-card-title">프로젝트 상세 통계</div>
        <div class="flex gap-2 items-center">
          <div class="form-group mb-0">
            <input type="search"
                   class="form-input form-input-sm"
                   placeholder="프로젝트 검색..."
                   v-model="searchQuery"
                   style="min-width: 200px;">
          </div>
          <button class="btn btn-sm btn-ghost-primary">
            <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
              <path d="M10 12a2 2 0 100-4 2 2 0 000 4z"/>
              <path fill-rule="evenodd" d="M.458 10C1.732 5.943 5.522 3 10 3s8.268 2.943 9.542 7c-1.274 4.057-5.064 7-9.542 7S1.732 14.057.458 10zM14 10a4 4 0 11-8 0 4 4 0 018 0z" clip-rule="evenodd"/>
            </svg>
            상세보기
          </button>
        </div>
      </div>
      <div class="widget-card-body p-0">
        <div class="table-wrapper">
          <table class="table table-hover table-sortable">
            <thead>
              <tr>
                <th>프로젝트명</th>
                <th>진행률</th>
                <th>완료 작업</th>
                <th>남은 작업</th>
                <th>팀 크기</th>
                <th>상태</th>
                <th>효율성</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="project in filteredProjectStats" :key="project.id">
                <td>
                  <div class="flex items-center gap-3">
                    <div class="w-10 h-10 rounded-lg flex items-center justify-center text-white font-bold"
                         :style="{ background: project.color }">
                      {{ project.name.charAt(0) }}
                    </div>
                    <div>
                      <div class="font-semibold text-neutral-900">{{ project.name }}</div>
                      <div class="text-body-xs text-muted">{{ project.category }}</div>
                    </div>
                  </div>
                </td>
                <td>
                  <div class="flex items-center gap-3">
                    <div class="progress" style="width: 100px;">
                      <div class="progress-bar" :class="`progress-bar-${project.progressType}`"
                           :style="{ width: project.progress + '%' }"></div>
                    </div>
                    <span class="text-body-sm font-semibold font-mono">{{ project.progress }}%</span>
                  </div>
                </td>
                <td>
                  <span class="badge badge-success badge-pill">{{ project.completedTasks }}</span>
                </td>
                <td>
                  <span class="badge badge-warning badge-pill">{{ project.remainingTasks }}</span>
                </td>
                <td>
                  <div class="flex items-center gap-1">
                    <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor" class="text-muted">
                      <path d="M9 6a3 3 0 11-6 0 3 3 0 016 0zM17 6a3 3 0 11-6 0 3 3 0 016 0zM12.93 17c.046-.327.07-.66.07-1a6.97 6.97 0 00-1.5-4.33A5 5 0 0119 16v1h-6.07zM6 11a5 5 0 015 5v1H1v-1a5 5 0 015-5z"/>
                    </svg>
                    <span class="text-body-sm">{{ project.teamSize }}</span>
                  </div>
                </td>
                <td>
                  <span class="badge" :class="`badge-${project.statusType}`">{{ project.status }}</span>
                </td>
                <td>
                  <div class="flex items-center gap-2">
                    <div class="progress progress-sm" style="width: 60px;">
                      <div class="progress-bar progress-bar-info" :style="{ width: project.efficiency + '%' }"></div>
                    </div>
                    <span class="text-body-xs text-muted">{{ project.efficiency }}%</span>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <!-- 알림 카드 -->
    <div class="grid grid-cols-2 md:grid-cols-1 gap-4">
      <div class="alert-card alert-card-success">
        <svg class="alert-card-icon" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"/>
        </svg>
        <div class="alert-card-content">
          <div class="alert-card-title">목표 달성!</div>
          <div class="alert-card-message">이번 달 프로젝트 완료율이 목표치를 초과했습니다. (112%)</div>
        </div>
      </div>
      <div class="alert-card alert-card-warning">
        <svg class="alert-card-icon" viewBox="0 0 20 20" fill="currentColor">
          <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/>
        </svg>
        <div class="alert-card-content">
          <div class="alert-card-title">주의 필요</div>
          <div class="alert-card-message">5개 프로젝트에서 일정 지연이 발생했습니다. 리소스 재할당을 검토하세요.</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
/**
 * 프로젝트 진척 통계 화면
 * 다양한 차트를 활용한 프로젝트 통계 대시보드
 *
 * @author 윤성민 책임
 * @since 2026-02-12
 */
import { ref, computed, onMounted, onUnmounted } from 'vue'
import type { ComponentPublicInstance } from 'vue'
import * as echarts from 'echarts'
import type { ECharts } from 'echarts'

// Refs
const progressTrendChartRef = ref<HTMLDivElement>()
const teamRadarChartRef = ref<HTMLDivElement>()
const statusDonutChartRef = ref<HTMLDivElement>()
const priorityPieChartRef = ref<HTMLDivElement>()
const monthlyBarChartRef = ref<HTMLDivElement>()
const gaugeChartRef = ref<HTMLDivElement>()
const funnelChartRef = ref<HTMLDivElement>()
const heatmapChartRef = ref<HTMLDivElement>()
const scatterChartRef = ref<HTMLDivElement>()
const stackedAreaChartRef = ref<HTMLDivElement>()
const treemapChartRef = ref<HTMLDivElement>()
const miniChartRefs = ref<(HTMLDivElement | null)[]>([])

// miniChartRef 설정 함수
function setMiniChartRef(el: Element | ComponentPublicInstance | null, index: number) {
  if (el && el instanceof HTMLDivElement) {
    miniChartRefs.value[index] = el
  }
}

const searchQuery = ref('')
const selectedPeriod = ref('monthly')
const lastUpdateTime = ref('')

// 차트 인스턴스
let progressTrendChart: ECharts | null = null
let teamRadarChart: ECharts | null = null
let statusDonutChart: ECharts | null = null
let priorityPieChart: ECharts | null = null
let monthlyBarChart: ECharts | null = null
let gaugeChart: ECharts | null = null
let funnelChart: ECharts | null = null
let heatmapChart: ECharts | null = null
let scatterChart: ECharts | null = null
let stackedAreaChart: ECharts | null = null
let treemapChart: ECharts | null = null
const miniCharts: ECharts[] = []

// 기간 선택
const periods = [
  { value: 'weekly', label: '주간' },
  { value: 'monthly', label: '월간' },
  { value: 'quarterly', label: '분기' },
  { value: 'yearly', label: '연간' }
]

// KPI 메트릭
const kpiMetrics = ref([
  {
    label: '전체 완료율',
    value: '78.5%',
    trend: 'up',
    changeText: '+5.2% 이번 달',
    colorClass: 'metric-card-primary'
  },
  {
    label: '평균 작업 속도',
    value: '24.3',
    trend: 'up',
    changeText: '+3.1 tasks/day',
    colorClass: 'metric-card-success'
  },
  {
    label: '팀 효율성',
    value: '92%',
    trend: 'neutral',
    changeText: '안정적',
    colorClass: 'metric-card-info'
  },
  {
    label: '지연 비율',
    value: '4.2%',
    trend: 'down',
    changeText: '-2.1% 개선',
    colorClass: 'metric-card-warning'
  }
])

// 총 작업 수
const totalTasks = computed(() => 1247)

// 프로젝트 통계 데이터
const projectStats = ref([
  {
    id: 1,
    name: 'AI 챗봇 시스템',
    category: '머신러닝',
    progress: 85,
    progressType: 'success',
    completedTasks: 127,
    remainingTasks: 23,
    teamSize: 8,
    status: '진행 중',
    statusType: 'success',
    efficiency: 92,
    color: 'linear-gradient(135deg, #3b82f6 0%, #2563eb 100%)'
  },
  {
    id: 2,
    name: '고객 포털 리뉴얼',
    category: '웹 애플리케이션',
    progress: 67,
    progressType: 'info',
    completedTasks: 89,
    remainingTasks: 44,
    teamSize: 12,
    status: '검토 중',
    statusType: 'warning',
    efficiency: 78,
    color: 'linear-gradient(135deg, #10b981 0%, #059669 100%)'
  },
  {
    id: 3,
    name: '모바일 앱 개발',
    category: 'iOS & Android',
    progress: 45,
    progressType: 'warning',
    completedTasks: 56,
    remainingTasks: 68,
    teamSize: 6,
    status: '시작',
    statusType: 'info',
    efficiency: 65,
    color: 'linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%)'
  },
  {
    id: 4,
    name: 'API 서버 구축',
    category: '백엔드',
    progress: 92,
    progressType: 'success',
    completedTasks: 145,
    remainingTasks: 13,
    teamSize: 5,
    status: '완료 임박',
    statusType: 'success',
    efficiency: 95,
    color: 'linear-gradient(135deg, #06b6d4 0%, #0891b2 100%)'
  },
  {
    id: 5,
    name: '보안 시스템 강화',
    category: '인프라',
    progress: 30,
    progressType: 'danger',
    completedTasks: 34,
    remainingTasks: 79,
    teamSize: 4,
    status: '지연',
    statusType: 'danger',
    efficiency: 58,
    color: 'linear-gradient(135deg, #ef4444 0%, #dc2626 100%)'
  },
  {
    id: 6,
    name: 'UI/UX 리디자인',
    category: '디자인',
    progress: 78,
    progressType: 'success',
    completedTasks: 98,
    remainingTasks: 28,
    teamSize: 7,
    status: '진행 중',
    statusType: 'success',
    efficiency: 88,
    color: 'linear-gradient(135deg, #ec4899 0%, #db2777 100%)'
  }
])

const filteredProjectStats = computed(() => {
  if (!searchQuery.value) return projectStats.value
  return projectStats.value.filter(project =>
    project.name.toLowerCase().includes(searchQuery.value.toLowerCase()) ||
    project.category.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
})

// 프로젝트 진행 추이 차트 (라인 + 바 혼합)
function initProgressTrendChart() {
  if (!progressTrendChartRef.value) return
  progressTrendChart = echarts.init(progressTrendChartRef.value)

  const months = ['1월', '2월', '3월', '4월', '5월', '6월', '7월', '8월', '9월', '10월', '11월', '12월']
  const completionRate = [65, 68, 72, 70, 75, 78, 80, 82, 79, 83, 85, 88]
  const taskCount = [120, 135, 150, 145, 168, 172, 180, 195, 188, 205, 218, 230]

  const option = {
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'cross',
        crossStyle: {
          color: '#999'
        }
      }
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: months,
      axisPointer: {
        type: 'shadow'
      }
    },
    yAxis: [
      {
        type: 'value',
        name: '완료율 (%)',
        min: 0,
        max: 100,
        axisLabel: {
          formatter: '{value} %'
        }
      },
      {
        type: 'value',
        name: '작업량',
        min: 0,
        max: 250,
        axisLabel: {
          formatter: '{value}'
        }
      }
    ],
    series: [
      {
        name: '완료율',
        type: 'line',
        smooth: true,
        data: completionRate,
        itemStyle: {
          color: '#3b82f6'
        },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(59, 130, 246, 0.3)' },
            { offset: 1, color: 'rgba(59, 130, 246, 0.05)' }
          ])
        }
      },
      {
        name: '작업량',
        type: 'bar',
        yAxisIndex: 1,
        data: taskCount,
        itemStyle: {
          color: '#10b981'
        }
      }
    ]
  }

  progressTrendChart.setOption(option)
}

// 팀 성과 레이더 차트
function initTeamRadarChart() {
  if (!teamRadarChartRef.value) return
  teamRadarChart = echarts.init(teamRadarChartRef.value)

  const option = {
    tooltip: {},
    radar: {
      indicator: [
        { name: '생산성', max: 100 },
        { name: '품질', max: 100 },
        { name: '협업', max: 100 },
        { name: '혁신', max: 100 },
        { name: '일정 준수', max: 100 }
      ],
      shape: 'circle',
      splitNumber: 4,
      axisName: {
        color: '#64748b'
      }
    },
    series: [{
      type: 'radar',
      data: [
        {
          value: [85, 90, 88, 75, 82],
          name: '개발팀',
          itemStyle: { color: '#3b82f6' },
          areaStyle: { color: 'rgba(59, 130, 246, 0.3)' }
        },
        {
          value: [78, 85, 92, 88, 80],
          name: '디자인팀',
          itemStyle: { color: '#10b981' },
          areaStyle: { color: 'rgba(16, 185, 129, 0.3)' }
        }
      ]
    }]
  }

  teamRadarChart.setOption(option)
}

// 프로젝트 상태 도넛 차트
function initStatusDonutChart() {
  if (!statusDonutChartRef.value) return
  statusDonutChart = echarts.init(statusDonutChartRef.value)

  const option = {
    tooltip: {
      trigger: 'item',
      formatter: '{a} <br/>{b}: {c} ({d}%)'
    },
    legend: {
      orient: 'vertical',
      right: '10%',
      top: 'center'
    },
    series: [
      {
        name: '프로젝트 상태',
        type: 'pie',
        radius: ['50%', '70%'],
        avoidLabelOverlap: false,
        itemStyle: {
          borderRadius: 10,
          borderColor: '#fff',
          borderWidth: 2
        },
        label: {
          show: false,
          position: 'center'
        },
        emphasis: {
          label: {
            show: true,
            fontSize: '20',
            fontWeight: 'bold'
          }
        },
        labelLine: {
          show: false
        },
        data: [
          { value: 42, name: '진행 중', itemStyle: { color: '#3b82f6' } },
          { value: 28, name: '완료', itemStyle: { color: '#10b981' } },
          { value: 15, name: '대기', itemStyle: { color: '#f59e0b' } },
          { value: 8, name: '지연', itemStyle: { color: '#ef4444' } },
          { value: 7, name: '보류', itemStyle: { color: '#64748b' } }
        ]
      }
    ]
  }

  statusDonutChart.setOption(option)
}

// 우선순위별 파이 차트
function initPriorityPieChart() {
  if (!priorityPieChartRef.value) return
  priorityPieChart = echarts.init(priorityPieChartRef.value)

  const option = {
    tooltip: {
      trigger: 'item'
    },
    legend: {
      bottom: '5%',
      left: 'center'
    },
    series: [
      {
        name: '우선순위',
        type: 'pie',
        radius: '60%',
        data: [
          { value: 450, name: '긴급', itemStyle: { color: '#ef4444' } },
          { value: 380, name: '높음', itemStyle: { color: '#f59e0b' } },
          { value: 267, name: '보통', itemStyle: { color: '#3b82f6' } },
          { value: 150, name: '낮음', itemStyle: { color: '#64748b' } }
        ],
        emphasis: {
          itemStyle: {
            shadowBlur: 10,
            shadowOffsetX: 0,
            shadowColor: 'rgba(0, 0, 0, 0.5)'
          }
        }
      }
    ]
  }

  priorityPieChart.setOption(option)
}

// 월별 바 차트
function initMonthlyBarChart() {
  if (!monthlyBarChartRef.value) return
  monthlyBarChart = echarts.init(monthlyBarChartRef.value)

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
      type: 'category',
      data: ['9월', '10월', '11월', '12월', '1월', '2월']
    },
    yAxis: {
      type: 'value'
    },
    series: [
      {
        name: '완료 작업',
        type: 'bar',
        data: [320, 332, 301, 334, 390, 410],
        itemStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: '#3b82f6' },
            { offset: 1, color: '#2563eb' }
          ])
        },
        barWidth: '60%'
      }
    ]
  }

  monthlyBarChart.setOption(option)
}

// 게이지 차트
function initGaugeChart() {
  if (!gaugeChartRef.value) return
  gaugeChart = echarts.init(gaugeChartRef.value)

  const option = {
    series: [
      {
        type: 'gauge',
        startAngle: 180,
        endAngle: 0,
        center: ['50%', '75%'],
        radius: '90%',
        min: 0,
        max: 100,
        splitNumber: 5,
        itemStyle: {
          color: '#10b981'
        },
        progress: {
          show: true,
          width: 18
        },
        pointer: {
          show: false
        },
        axisLine: {
          lineStyle: {
            width: 18
          }
        },
        axisTick: {
          show: false
        },
        splitLine: {
          length: 12,
          lineStyle: {
            width: 2,
            color: '#999'
          }
        },
        axisLabel: {
          distance: 20,
          color: '#999',
          fontSize: 12
        },
        anchor: {
          show: false
        },
        title: {
          show: false
        },
        detail: {
          valueAnimation: true,
          formatter: '{value}%',
          color: '#10b981',
          fontSize: 28,
          fontWeight: 'bold',
          offsetCenter: [0, '-30%']
        },
        data: [
          {
            value: 78.5
          }
        ]
      }
    ]
  }

  gaugeChart.setOption(option)
}

// 펀널 차트
function initFunnelChart() {
  if (!funnelChartRef.value) return
  funnelChart = echarts.init(funnelChartRef.value)

  const option = {
    tooltip: {
      trigger: 'item',
      formatter: '{a} <br/>{b} : {c}'
    },
    series: [
      {
        name: '이슈 처리',
        type: 'funnel',
        left: '10%',
        width: '80%',
        label: {
          formatter: '{b}: {c}'
        },
        labelLine: {
          show: false
        },
        itemStyle: {
          borderColor: '#fff',
          borderWidth: 1
        },
        data: [
          { value: 320, name: '접수', itemStyle: { color: '#3b82f6' } },
          { value: 240, name: '분석 중', itemStyle: { color: '#8b5cf6' } },
          { value: 180, name: '처리 중', itemStyle: { color: '#f59e0b' } },
          { value: 120, name: '검증', itemStyle: { color: '#10b981' } },
          { value: 95, name: '완료', itemStyle: { color: '#06b6d4' } }
        ]
      }
    ]
  }

  funnelChart.setOption(option)
}

// 히트맵 차트
function initHeatmapChart() {
  if (!heatmapChartRef.value) return
  heatmapChart = echarts.init(heatmapChartRef.value)

  const hours = ['0시', '3시', '6시', '9시', '12시', '15시', '18시', '21시']
  const days = ['월', '화', '수', '목', '금', '토', '일']

  const data: [number, number, number][] = []
  for (let i = 0; i < days.length; i++) {
    for (let j = 0; j < hours.length; j++) {
      const value = Math.floor(Math.random() * 100)
      data.push([j, i, value])
    }
  }

  const option = {
    tooltip: {
      position: 'top'
    },
    grid: {
      height: '60%',
      top: '10%',
      left: '10%',
      right: '5%'
    },
    xAxis: {
      type: 'category',
      data: hours,
      splitArea: {
        show: true
      }
    },
    yAxis: {
      type: 'category',
      data: days,
      splitArea: {
        show: true
      }
    },
    visualMap: {
      min: 0,
      max: 100,
      calculable: true,
      orient: 'horizontal',
      left: 'center',
      bottom: '5%',
      inRange: {
        color: ['#e0f2fe', '#0891b2', '#164e63']
      }
    },
    series: [
      {
        name: '작업 시간',
        type: 'heatmap',
        data: data,
        label: {
          show: false
        },
        emphasis: {
          itemStyle: {
            shadowBlur: 10,
            shadowColor: 'rgba(0, 0, 0, 0.5)'
          }
        }
      }
    ]
  }

  heatmapChart.setOption(option)
}

// 산점도 차트
function initScatterChart() {
  if (!scatterChartRef.value) return
  scatterChart = echarts.init(scatterChartRef.value)

  const projects = [
    [25, 85, 'AI 챗봇'], [40, 67, '고객 포털'], [60, 45, '모바일 앱'],
    [20, 92, 'API 서버'], [70, 30, '보안 시스템'], [35, 78, 'UI/UX'],
    [50, 55, '데이터 분석'], [30, 82, '클라우드 마이그레이션'],
    [65, 38, 'IoT 플랫폼'], [45, 72, '결제 시스템']
  ]

  const option = {
    tooltip: {
      formatter: (params: any) => {
        return `${params.data[2]}<br/>난이도: ${params.data[0]}<br/>진행률: ${params.data[1]}%`
      }
    },
    grid: {
      left: '10%',
      right: '5%',
      bottom: '10%',
      top: '10%',
      containLabel: true
    },
    xAxis: {
      name: '난이도',
      nameLocation: 'center',
      nameGap: 25,
      min: 0,
      max: 100
    },
    yAxis: {
      name: '진행률 (%)',
      nameLocation: 'center',
      nameGap: 40,
      min: 0,
      max: 100
    },
    series: [
      {
        type: 'scatter',
        symbolSize: 20,
        data: projects,
        itemStyle: {
          color: new echarts.graphic.RadialGradient(0.4, 0.3, 1, [
            { offset: 0, color: '#3b82f6' },
            { offset: 1, color: '#1d4ed8' }
          ])
        },
        emphasis: {
          itemStyle: {
            shadowBlur: 10,
            shadowColor: 'rgba(59, 130, 246, 0.5)',
            shadowOffsetY: 5
          }
        }
      }
    ]
  }

  scatterChart.setOption(option)
}

// 스택 영역 차트
function initStackedAreaChart() {
  if (!stackedAreaChartRef.value) return
  stackedAreaChart = echarts.init(stackedAreaChartRef.value)

  const option = {
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'cross',
        label: {
          backgroundColor: '#6a7985'
        }
      }
    },
    legend: {
      data: ['개발', '디자인', '테스트', 'QA']
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: ['1주', '2주', '3주', '4주', '5주', '6주', '7주', '8주']
    },
    yAxis: {
      type: 'value'
    },
    series: [
      {
        name: '개발',
        type: 'line',
        stack: 'Total',
        areaStyle: {},
        emphasis: { focus: 'series' },
        data: [120, 132, 101, 134, 90, 230, 210, 245],
        itemStyle: { color: '#3b82f6' }
      },
      {
        name: '디자인',
        type: 'line',
        stack: 'Total',
        areaStyle: {},
        emphasis: { focus: 'series' },
        data: [220, 182, 191, 234, 290, 330, 310, 285],
        itemStyle: { color: '#8b5cf6' }
      },
      {
        name: '테스트',
        type: 'line',
        stack: 'Total',
        areaStyle: {},
        emphasis: { focus: 'series' },
        data: [150, 232, 201, 154, 190, 330, 410, 395],
        itemStyle: { color: '#10b981' }
      },
      {
        name: 'QA',
        type: 'line',
        stack: 'Total',
        areaStyle: {},
        emphasis: { focus: 'series' },
        data: [320, 332, 301, 334, 390, 330, 320, 345],
        itemStyle: { color: '#f59e0b' }
      }
    ]
  }

  stackedAreaChart.setOption(option)
}

// 트리맵 차트
function initTreemapChart() {
  if (!treemapChartRef.value) return
  treemapChart = echarts.init(treemapChartRef.value)

  const option = {
    tooltip: {},
    series: [
      {
        type: 'treemap',
        data: [
          {
            name: '개발팀',
            value: 450,
            itemStyle: { color: '#3b82f6' },
            children: [
              { name: '백엔드', value: 180, itemStyle: { color: '#2563eb' } },
              { name: '프론트엔드', value: 150, itemStyle: { color: '#60a5fa' } },
              { name: 'DevOps', value: 120, itemStyle: { color: '#93c5fd' } }
            ]
          },
          {
            name: '디자인팀',
            value: 280,
            itemStyle: { color: '#8b5cf6' },
            children: [
              { name: 'UI', value: 150, itemStyle: { color: '#7c3aed' } },
              { name: 'UX', value: 130, itemStyle: { color: '#a78bfa' } }
            ]
          },
          {
            name: 'QA팀',
            value: 220,
            itemStyle: { color: '#10b981' },
            children: [
              { name: '기능 테스트', value: 120, itemStyle: { color: '#059669' } },
              { name: '성능 테스트', value: 100, itemStyle: { color: '#34d399' } }
            ]
          },
          {
            name: '기획팀',
            value: 180,
            itemStyle: { color: '#f59e0b' }
          }
        ],
        label: {
          show: true,
          formatter: '{b}\n{c}'
        },
        breadcrumb: {
          show: false
        }
      }
    ]
  }

  treemapChart.setOption(option)
}

// 미니 차트 초기화
function initMiniCharts() {
  miniChartRefs.value.forEach((ref, index) => {
    if (!ref) return

    const chart = echarts.init(ref)
    miniCharts.push(chart)

    // 간단한 라인 차트 데이터
    const data = Array.from({ length: 12 }, () => Math.floor(Math.random() * 100) + 50)

    const option = {
      grid: {
        left: 0,
        right: 0,
        top: 0,
        bottom: 0
      },
      xAxis: {
        type: 'category',
        show: false,
        data: Array.from({ length: 12 }, (_, i) => i)
      },
      yAxis: {
        type: 'value',
        show: false
      },
      series: [
        {
          type: 'line',
          smooth: true,
          symbol: 'none',
          lineStyle: {
            color: index === 0 ? '#3b82f6' : index === 1 ? '#10b981' : index === 2 ? '#8b5cf6' : '#f59e0b',
            width: 2
          },
          areaStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: index === 0 ? 'rgba(59, 130, 246, 0.3)' : index === 1 ? 'rgba(16, 185, 129, 0.3)' : index === 2 ? 'rgba(139, 92, 246, 0.3)' : 'rgba(245, 158, 11, 0.3)' },
              { offset: 1, color: index === 0 ? 'rgba(59, 130, 246, 0.05)' : index === 1 ? 'rgba(16, 185, 129, 0.05)' : index === 2 ? 'rgba(139, 92, 246, 0.05)' : 'rgba(245, 158, 11, 0.05)' }
            ])
          },
          data: data
        }
      ]
    }

    chart.setOption(option)
  })
}

// 모든 차트 새로고침
function refreshAllCharts() {
  console.log('모든 차트 새로고침')
  progressTrendChart?.setOption(progressTrendChart.getOption(), true)
  teamRadarChart?.setOption(teamRadarChart.getOption(), true)
  statusDonutChart?.setOption(statusDonutChart.getOption(), true)
  priorityPieChart?.setOption(priorityPieChart.getOption(), true)
  monthlyBarChart?.setOption(monthlyBarChart.getOption(), true)
  gaugeChart?.setOption(gaugeChart.getOption(), true)
  funnelChart?.setOption(funnelChart.getOption(), true)
  heatmapChart?.setOption(heatmapChart.getOption(), true)
  scatterChart?.setOption(scatterChart.getOption(), true)
  stackedAreaChart?.setOption(stackedAreaChart.getOption(), true)
  treemapChart?.setOption(treemapChart.getOption(), true)
}

// 시간 업데이트
function updateTime() {
  const now = new Date()
  lastUpdateTime.value = now.toLocaleTimeString('ko-KR', {
    hour: '2-digit',
    minute: '2-digit'
  })
}

// 윈도우 리사이즈 핸들러
function handleResize() {
  progressTrendChart?.resize()
  teamRadarChart?.resize()
  statusDonutChart?.resize()
  priorityPieChart?.resize()
  monthlyBarChart?.resize()
  gaugeChart?.resize()
  funnelChart?.resize()
  heatmapChart?.resize()
  scatterChart?.resize()
  stackedAreaChart?.resize()
  treemapChart?.resize()
  miniCharts.forEach(chart => chart.resize())
}

onMounted(() => {
  updateTime()
  setInterval(updateTime, 60000)

  // 차트 초기화는 DOM이 완전히 렌더링된 후 실행
  setTimeout(() => {
    initProgressTrendChart()
    initTeamRadarChart()
    initStatusDonutChart()
    initPriorityPieChart()
    initMonthlyBarChart()
    initGaugeChart()
    initFunnelChart()
    initHeatmapChart()
    initScatterChart()
    initStackedAreaChart()
    initTreemapChart()
    initMiniCharts()
  }, 100)

  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  progressTrendChart?.dispose()
  teamRadarChart?.dispose()
  statusDonutChart?.dispose()
  priorityPieChart?.dispose()
  monthlyBarChart?.dispose()
  gaugeChart?.dispose()
  funnelChart?.dispose()
  heatmapChart?.dispose()
  scatterChart?.dispose()
  stackedAreaChart?.dispose()
  treemapChart?.dispose()
  miniCharts.forEach(chart => chart.dispose())
  window.removeEventListener('resize', handleResize)
})
</script>

<style scoped>
/* 메트릭 카드 아이콘 스타일 */
.metric-card-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 1rem;
  color: white;
}

/* 위젯 카드 스타일 */
.widget-card {
  background: var(--color-bg-primary);
  border: 1px solid var(--color-neutral-200);
  border-radius: 12px;
  box-shadow: var(--shadow-sm);
  overflow: hidden;
  transition: all var(--duration-fast);
}

.widget-card:hover {
  box-shadow: var(--shadow-md);
}

.widget-card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1.25rem 1.5rem;
  border-bottom: 1px solid var(--color-neutral-200);
}

.widget-card-title {
  font-size: 1.125rem;
  font-weight: 600;
  color: var(--color-neutral-900);
}

.widget-card-body {
  padding: 1.5rem;
}

/* 아바타 스타일 */
.avatar {
  width: 32px;
  height: 32px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: white;
  font-weight: 600;
  font-size: 0.875rem;
  flex-shrink: 0;
}

.avatar-sm {
  width: 28px;
  height: 28px;
  font-size: 0.75rem;
}

/* 폼 체크박스 */
.form-checkbox {
  width: 1rem;
  height: 1rem;
  border: 1px solid var(--color-neutral-300);
  border-radius: 4px;
  cursor: pointer;
}
</style>

