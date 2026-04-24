import { supabase } from './supabase'

const DB_NAME = 'gymlog-offline'
const DB_VERSION = 1
const STORE_NAME = 'pending_sets'
const NET_TIMEOUT_MS = 8000

let db = null

async function getDb() {
  if (db) return db
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION)
    request.onupgradeneeded = (e) => {
      const database = e.target.result
      if (!database.objectStoreNames.contains(STORE_NAME)) {
        database.createObjectStore(STORE_NAME, { keyPath: 'id' })
      }
    }
    request.onsuccess = (e) => { db = e.target.result; resolve(db) }
    request.onerror = () => reject(request.error)
  })
}

export async function queueSetLog(setLog) {
  const database = await getDb()
  return new Promise((resolve, reject) => {
    const tx = database.transaction(STORE_NAME, 'readwrite')
    tx.objectStore(STORE_NAME).put({ ...setLog, _pending: true })
    tx.oncomplete = resolve
    tx.onerror = () => reject(tx.error)
  })
}

export async function getPendingLogs() {
  const database = await getDb()
  return new Promise((resolve, reject) => {
    const tx = database.transaction(STORE_NAME, 'readonly')
    const request = tx.objectStore(STORE_NAME).getAll()
    request.onsuccess = () => resolve(request.result)
    request.onerror = () => reject(request.error)
  })
}

export async function removePendingLog(id) {
  const database = await getDb()
  return new Promise((resolve, reject) => {
    const tx = database.transaction(STORE_NAME, 'readwrite')
    tx.objectStore(STORE_NAME).delete(id)
    tx.oncomplete = resolve
    tx.onerror = () => reject(tx.error)
  })
}

function withTimeout(promise, ms, controller) {
  return new Promise((resolve, reject) => {
    const t = setTimeout(() => {
      controller?.abort()
      reject(new Error('network timeout'))
    }, ms)
    promise.then(
      (v) => { clearTimeout(t); resolve(v) },
      (e) => { clearTimeout(t); reject(e) }
    )
  })
}

export async function pushSetLog(payload) {
  const { _pending, ...data } = payload
  const controller = new AbortController()
  const req = supabase.from('set_logs').upsert(data).abortSignal(controller.signal)
  const { error } = await withTimeout(req, NET_TIMEOUT_MS, controller)
  if (error) throw error
  await removePendingLog(data.id)
}

let syncing = false
export async function syncPendingLogs() {
  if (syncing) return
  syncing = true
  try {
    const pending = await getPendingLogs()
    for (const log of pending) {
      try { await pushSetLog(log) } catch { /* leave in queue */ }
    }
  } finally {
    syncing = false
  }
}

if (typeof window !== 'undefined') {
  window.addEventListener('online', () => syncPendingLogs())
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible') syncPendingLogs()
  })
}
