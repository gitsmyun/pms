/**
 * 메인 엔트리
 *
 * @author 윤성민 책임
 * @since 2026-01-05
 */
import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import './style.css'

const app = createApp(App)
app.use(router)
app.mount('#app')

