import { supabase } from './supabase'

const DB_NAME = 'gymlog-offline'
const DB_VERSION = 1
const STORE_NAME = 'pending_sets'

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

export async function syncPendingLogs() {
  const pending = await getPendingLogs()
  if (!pending.length) return

  for (const log of pending) {
    const { _pending, ...data } = log
    const { error } = await supabase.from('set_logs').upsert(data)
    if (!error) await removePendingLog(log.id)
  }
}

// Listen for online event and auto-sync
if (typeof window !== 'undefined') {
  window.addEventListener('online', () => syncPendingLogs())
}
