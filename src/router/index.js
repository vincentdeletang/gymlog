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
// transition. The fade/slide-up transitions take up to 300ms, so we run an
// immediate pass AND a delayed pass that catches anything still mid-leave
// at navigation time.
function sweepOrphanOverlays() {
  document.querySelectorAll('body > .sheet-overlay, body > .sheet-panel')
    .forEach(el => el.remove())
}
router.afterEach(() => {
  sweepOrphanOverlays()
  setTimeout(sweepOrphanOverlays, 350)
})

// Catches the case where a leave transition COMPLETES naturally but Vue still
// didn't unmount the element (the bug we're hunting): the transition ends with
// pointer-events: none on the element, and it stays attached to <body>. We
// listen at the document level so we don't miss anything regardless of which
// view triggered it.
if (typeof window !== 'undefined') {
  document.addEventListener('transitionend', (e) => {
    const el = e.target
    if (!(el instanceof HTMLElement)) return
    if (el.parentElement !== document.body) return
    if (!el.classList.contains('sheet-overlay') && !el.classList.contains('sheet-panel')) return
    if (getComputedStyle(el).pointerEvents === 'none') el.remove()
  }, true)
}

export default router
