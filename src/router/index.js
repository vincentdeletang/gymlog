import { createRouter, createWebHashHistory } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { isValidISODate, todayISO } from '@/lib/formatDate'

const routes = [
  { path: '/', redirect: '/today' },
  { path: '/today/:date?', component: () => import('@/views/TodayView.vue'),    meta: { requiresAuth: true } },
  { path: '/history',      component: () => import('@/views/HistoryView.vue'),  meta: { requiresAuth: true } },
  { path: '/stats',        component: () => import('@/views/StatsView.vue'),    meta: { requiresAuth: true } },
  { path: '/program',      component: () => import('@/views/ProgramView.vue'),  meta: { requiresAuth: true } },
  { path: '/settings',     component: () => import('@/views/SettingsView.vue'), meta: { requiresAuth: true } },
  { path: '/auth',         component: () => import('@/views/AuthView.vue') },
]

const router = createRouter({
  history: createWebHashHistory(),
  routes,
})

router.beforeEach(async (to) => {
  if (to.path.startsWith('/today/') && to.params.date) {
    const d = to.params.date
    if (!isValidISODate(d) || d > todayISO()) return '/today'
  }

  if (!to.meta.requiresAuth) return true
  const { data: { session } } = await supabase.auth.getSession()
  if (!session) return '/auth'
  return true
})

// Sweep up any teleported overlay that got orphaned by an interrupted leave
// transition. Without this, an invisible <div.sheet-overlay> can stay pinned
// to <body> and silently block every tap on the bottom of the screen
// (BottomNav included) until the user reloads.
router.afterEach(() => {
  document.querySelectorAll('body > .sheet-overlay, body > .sheet-panel')
    .forEach(el => el.remove())
})

export default router
