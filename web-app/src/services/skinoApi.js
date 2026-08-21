const DEFAULT_API_URL = 'http://127.0.0.1:8000/api'
const PRODUCTION_API_URL = 'https://skino-skin-analysis.onrender.com/api'
const PRODUCTION_GOOGLE_CLIENT_ID = '148577531434-p1e2ued43tb5dhe5tkptpaa4g23uvipk.apps.googleusercontent.com'
const SESSION_KEY = 'skino.web.auth.session'

export const apiBaseUrl = (import.meta.env.VITE_API_BASE_URL || (import.meta.env.PROD ? PRODUCTION_API_URL : DEFAULT_API_URL)).replace(/\/$/, '')
export const googleClientId = import.meta.env.VITE_GOOGLE_CLIENT_ID || (import.meta.env.PROD ? PRODUCTION_GOOGLE_CLIENT_ID : '')

function validationMessage(payload, fallback) {
  const errors = payload?.errors
  if (errors && typeof errors === 'object') {
    for (const messages of Object.values(errors)) {
      if (Array.isArray(messages) && messages.length) return String(messages[0])
    }
  }
  return payload?.message || fallback
}

function requestError(message, code) {
  const error = new Error(message)
  error.code = code
  return error
}

async function request(path, { method = 'GET', token, body, formData, signal, timeoutMs = 15000 } = {}) {
  const headers = { Accept: 'application/json' }
  if (token) headers.Authorization = `Bearer ${token}`
  if (!formData && body !== undefined) headers['Content-Type'] = 'application/json'

  if (typeof navigator !== 'undefined' && navigator.onLine === false) {
    throw requestError('You appear to be offline. Reconnect and try again.', 'OFFLINE')
  }

  const controller = new AbortController()
  let timedOut = false
  const abortFromCaller = () => controller.abort()
  signal?.addEventListener('abort', abortFromCaller, { once: true })
  const timeoutId = window.setTimeout(() => {
    timedOut = true
    controller.abort()
  }, timeoutMs)

  let response
  try {
    response = await fetch(`${apiBaseUrl}${path}`, {
      method,
      headers,
      body: formData || (body === undefined ? undefined : JSON.stringify(body)),
      signal: controller.signal,
    })
  } catch (error) {
    if (timedOut) throw requestError('Skino took too long to respond. Please retry.', 'TIMEOUT')
    if (signal?.aborted) throw requestError('Request cancelled.', 'CANCELLED')
    if (error?.name === 'AbortError') throw requestError('Request cancelled.', 'CANCELLED')
    throw requestError('Skino could not reach the server. Check your connection and try again.', 'NETWORK')
  } finally {
    window.clearTimeout(timeoutId)
    signal?.removeEventListener('abort', abortFromCaller)
  }

  if (response.status === 204) return null
  const contentType = response.headers.get('content-type') || ''
  const payload = contentType.includes('application/json') ? await response.json() : null
  if (!response.ok) throw new Error(validationMessage(payload, `Skino request failed (${response.status}).`))
  return payload
}

export function readSession() {
  try {
    return JSON.parse(localStorage.getItem(SESSION_KEY) || 'null')
  } catch {
    localStorage.removeItem(SESSION_KEY)
    return null
  }
}

export function saveSession(session) {
  localStorage.setItem(SESSION_KEY, JSON.stringify(session))
}

export function clearSession() {
  localStorage.removeItem(SESSION_KEY)
}

export async function loginWithPassword(email, password) {
  const payload = await request('/auth/login', { method: 'POST', body: { email, password } })
  return payload.data
}

export async function loginWithGoogle(idToken) {
  const payload = await request('/auth/google', { method: 'POST', body: { id_token: idToken } })
  return payload.data
}

export async function fetchMe(token) {
  const payload = await request('/me', { token })
  return payload.data
}

export async function fetchProfile(token) {
  const payload = await request('/profile', { token })
  return payload.data
}

export async function updateProfile(token, profile) {
  const payload = await request('/profile', { method: 'PUT', token, body: profile })
  return payload.data
}

export async function logout(token) {
  return request('/auth/logout', { method: 'POST', token })
}

export async function fetchTrainingConsent(token) {
  const payload = await request('/privacy/model-training-consent', { token })
  return payload.data
}

export async function updateTrainingConsent(token, granted) {
  const payload = await request('/privacy/model-training-consent', { method: 'PUT', token, body: { granted } })
  return payload.data
}

export async function fetchRequiredConsents(token) {
  const payload = await request('/privacy/required-consents', { token })
  return payload.data
}

export async function updateRequiredConsents(token, choices) {
  const payload = await request('/privacy/required-consents', {
    method: 'PUT',
    token,
    body: choices,
  })
  return payload.data
}

export async function analyzeSkin(token, image, allowModelTraining = false, captureContext = {}, signal) {
  const formData = new FormData()
  formData.append('image', image, image.name || 'skino-scan.jpg')
  formData.append('allow_model_training', allowModelTraining ? '1' : '0')
  formData.append('capture_mode', captureContext.mode || 'single_upload')
  formData.append('frame_count', String(captureContext.frameCount || 1))
  formData.append('client_quality_score', String(captureContext.qualityScore || 0))
  formData.append('device_category', captureContext.deviceCategory || 'unknown')
  for (const frame of (captureContext.frames || []).slice(0, 2)) {
    formData.append('frames[]', frame, frame.name || 'skino-frame.jpg')
  }
  if (captureContext.landmarks?.length >= 468) {
    formData.append('face_landmarks', JSON.stringify(captureContext.landmarks))
  }
  const payload = await request('/skin-analyses', {
    method: 'POST',
    token,
    formData,
    signal,
    timeoutMs: 90000,
  })
  return payload.data
}

export async function fetchScanHistory(token) {
  const payload = await request('/skin-analyses?per_page=20', { token })
  return payload.data || []
}

export async function deleteScan(token, analysisId) {
  return request(`/skin-analyses/${analysisId}`, { method: 'DELETE', token })
}

export async function fetchRoutine(token) {
  const payload = await request('/routine', { token })
  return payload.data
}

export async function startRoutine(token, skinAnalysisId) {
  const payload = await request('/routine/start', { method: 'POST', token, body: { skin_analysis_id: skinAnalysisId } })
  return payload.data
}

export async function updateRoutineToday(token, fields) {
  const payload = await request('/routine/today', { method: 'PUT', token, body: fields })
  return payload.data
}

export async function stopRoutine(token) {
  return request('/routine', { method: 'DELETE', token })
}

export async function askRoutineAssistant(token, message, context = {}) {
  const payload = await request('/chat/routine-assistant', {
    method: 'POST',
    token,
    body: { message, context },
  })
  return payload.data?.reply || ''
}

export async function createAppointmentRequest(token, appointment) {
  const payload = await request('/appointment-requests', {
    method: 'POST',
    token,
    body: appointment,
  })
  return payload.data
}

export function loadGoogleIdentity() {
  if (window.google?.accounts?.id) return Promise.resolve(window.google)
  return new Promise((resolve, reject) => {
    const existing = document.querySelector('script[data-skino-google]')
    if (existing) {
      existing.addEventListener('load', () => resolve(window.google), { once: true })
      existing.addEventListener('error', () => reject(new Error('Google Sign-In could not load.')), { once: true })
      return
    }
    const script = document.createElement('script')
    script.src = 'https://accounts.google.com/gsi/client'
    script.async = true
    script.defer = true
    script.dataset.skinoGoogle = 'true'
    script.onload = () => resolve(window.google)
    script.onerror = () => reject(new Error('Google Sign-In could not load.'))
    document.head.appendChild(script)
  })
}
