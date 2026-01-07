/**
 * 라우터 설정
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 */
import { createRouter, createWebHistory } from 'vue-router'
import ProjectsView from '@/views/ProjectsView.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/',
      name: 'projects',
      component: ProjectsView
    }
  ]
})

export default router

