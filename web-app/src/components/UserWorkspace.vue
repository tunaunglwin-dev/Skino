<script setup>
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import { FaceDetector, FaceLandmarker, FilesetResolver } from '@mediapipe/tasks-vision'
import PricingPlans from './PricingPlans.vue'
import logo from '../assets/branding/skino_logo.webp'
import scanIcon from '../assets/branding/skino_icon_scan.png'
import routineIcon from '../assets/branding/skino_icon_routine.png'
import historyIcon from '../assets/branding/skino_icon_history.webp'
import progressIcon from '../assets/branding/skino_icon_progress.webp'
import specialistIcon from '../assets/branding/skino_icon_specialist.png'
import cameraMascot from '../assets/branding/skino_little_guy_magnifier.png'
import calmMascot from '../assets/branding/skino_little_guy_calm.png'
import cleanserProduct from '../assets/branding/routine-gentle-cleanser.webp'
import serumProduct from '../assets/branding/routine-brightening-serum.webp'
import moisturizerProduct from '../assets/branding/routine-moisturizer.webp'
import sunscreenProduct from '../assets/branding/routine-sunscreen.webp'
import {
  analyzeSkin,
  createAppointmentRequest,
  deleteScan,
  fetchRoutine,
  fetchProfile,
  fetchScanHistory,
  startRoutine,
  stopRoutine,
  updateProfile,
  updateRoutineToday,
  updateTrainingConsent,
} from '../services/skinoApi'

const props = defineProps({
  session: { type: Object, required: true },
  allowModelTraining: { type: Boolean, default: false },
})
const emit = defineEmits(['logout', 'profile-updated', 'training-consent-updated'])

const activeView = ref('home')
const history = ref([])
const routine = ref(null)
const result = ref(null)
const capturedFile = ref(null)
const capturedFrames = ref([])
const previewUrl = ref('')
const video = ref(null)
const canvas = ref(null)
const stream = ref(null)
const cameraActive = ref(false)
const faceGuide = ref({ state: 'idle', message: 'ကင်မရာဖွင့်ပြီး မျက်နှာတစ်ခုလုံးကို frame အတွင်းထားပါ။', confidence: 0 })
const inputValidated = ref(false)
const loading = ref(false)
const pageLoading = ref(true)
const error = ref('')
const notice = ref('')
const online = ref(navigator.onLine)
const scanFailure = ref('')
const loadErrors = ref({})
const appointmentLoading = ref(false)
const appointmentSuccess = ref(null)
const profileOpen = ref(false)
const pricingOpen = ref(false)
const profile = ref(null)
const profileSaving = ref(false)
const localTrainingConsent = ref(props.allowModelTraining)
const profileForm = ref({ name: '', age_band: '', skin_tone_scale: null, skin_goals: [] })
const captureProgress = ref(0)
const captureQualityScore = ref(0)
const captureMode = ref('single_upload')
const capturingFrames = ref(false)
const developerOverlay = ref(false)
const analysisProgress = ref(0)
const analysisStageIndex = ref(0)
const retryingSection = ref('')
const skinMapOpen = ref(false)
const activeZoneKey = ref('')
const selectedRoutineDate = ref(new Date().toISOString().slice(0, 10))
const appointmentScanId = ref('')
const appointmentForm = ref({
  name: '',
  email: '',
  phone: '',
  preferredContactMethod: 'in_app',
  preferredDate: '',
  requestedSpecialist: 'Dr. May Thandar',
  beautyGoal: '',
  notes: '',
})

let analysisController = null
let analysisProgressTimer = null

const analysisStages = [
  { title: 'ပုံကို လုံခြုံစွာ ပြင်ဆင်နေသည်', detail: 'Preparing your selected frame' },
  { title: 'ပုံအရည်အသွေး စစ်ဆေးနေသည်', detail: 'Checking lighting, clarity and face position' },
  { title: 'အသားအရေ အချက်များကို ခွဲခြမ်းနေသည်', detail: 'Analyzing visible skin signals and zones' },
  { title: 'ရလဒ်နှင့် routine ကို ပြင်ဆင်နေသည်', detail: 'Building your clear result and care guidance' },
]

const user = computed(() => profile.value || props.session.user || {})
const token = computed(() => props.session.token)
const latestResult = computed(() => result.value || history.value[0] || null)
const selectedAppointmentScan = computed(() => history.value.find((item) => String(item.id) === appointmentScanId.value) || latestResult.value)
const currentAnalysisStage = computed(() => analysisStages[analysisStageIndex.value] || analysisStages[0])
const operationLabel = computed(() => {
  if (activeView.value === 'routine') return 'Routine ကို လုံခြုံစွာ သိမ်းနေသည်…'
  if (activeView.value === 'history') return 'Scan history ကို ပြင်ဆင်နေသည်…'
  if (activeView.value === 'result') return 'Care plan ကို ပြင်ဆင်နေသည်…'
  return 'အချက်အလက်ကို သိမ်းနေသည်…'
})
const cameraSupported = computed(() => Boolean(navigator.mediaDevices?.getUserMedia))
function routineTaskFromStep(step, index) {
  const value = String(step || '').trim()
  const lower = value.toLowerCase()
  const key = lower.replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '') || `step-${index + 1}`
  if (lower.includes('clean')) return { key, legacyKey: 'cleanser', title: routineStepMy(value), note: 'နူးညံ့စွာ သန့်စင်ပြီး ရေဖြင့် ဆေးချပါ', image: cleanserProduct }
  if (lower.includes('serum')) return { key, legacyKey: 'serum', title: routineStepMy(value), note: 'အရေပြားပေါ် နူးညံ့စွာ ပုတ်လိမ်းပါ', image: serumProduct }
  if (lower.includes('moistur')) return { key, legacyKey: 'moisturizer', title: routineStepMy(value), note: 'မျက်နှာအနှံ့ ညီညာစွာ လိမ်းပါ', image: moisturizerProduct }
  if (lower.includes('sun') || lower.includes('spf')) return { key, legacyKey: 'sunscreen', title: routineStepMy(value), note: 'မနက်ပိုင်း အပြင်မထွက်မီ လိမ်းပါ', image: sunscreenProduct }
  return { key, legacyKey: key, title: routineStepMy(value), note: value, image: moisturizerProduct }
}

const routineTaskGroups = computed(() => {
  const planSteps = routine.value?.routine?.steps?.length
    ? routine.value.routine.steps
    : ['gentle cleanser', 'brightening serum', 'light moisturizer', 'broad-spectrum sunscreen']
  const tasks = planSteps.map(routineTaskFromStep)
  const morningTasks = tasks
  const nightTasks = tasks.filter((task) => task.legacyKey !== 'sunscreen')
  return [
  {
    key: 'morning',
    title: 'မနက်ပိုင်း',
    subtitle: 'နေ့သစ်အတွက် ကာကွယ်မှုနှင့် ရေဓာတ်ဖြည့်ခြင်း',
    tasks: morningTasks,
  },
  {
    key: 'night',
    title: 'ညပိုင်း',
    subtitle: 'နေ့တာကုန်ပြီးနောက် သန့်စင်၍ ပြန်လည်ထိန်းသိမ်းခြင်း',
    tasks: nightTasks,
  },
  ]
})
const todayProgress = computed(() => {
  if (!routine.value) return 0
  const total = routineTaskGroups.value.reduce((sum, group) => sum + group.tasks.length, 0)
  const complete = routineTaskGroups.value.reduce((sum, group) => sum + group.tasks.filter((task) => routineTaskDone(group, task)).length, 0)
  return total ? Math.round((complete / total) * 100) : 0
})
const canCapture = computed(() => (
  ['good', 'unavailable'].includes(faceGuide.value.state)
))
const canAnalyze = computed(() => Boolean(capturedFile.value && inputValidated.value))
const routineCalendarDays = computed(() => routine.value?.week?.check_ins || [])
const routineCalendarTitle = computed(() => {
  const date = new Date(`${selectedRoutineDate.value}T00:00:00`)
  return `${date.getFullYear()} ခုနှစ် ${date.getMonth() + 1} လ`
})

const ageBandOptions = [
  { value: '', label: 'မဖြည့်လိုပါ' },
  { value: 'under_18', label: 'အသက် ၁၈ နှစ်အောက်' },
  { value: '18_24', label: '၁၈–၂၄' },
  { value: '25_34', label: '၂၅–၃၄' },
  { value: '35_44', label: '၃၅–၄၄' },
  { value: '45_54', label: '၄၅–၅၄' },
  { value: '55_plus', label: '၅၅ နှစ်နှင့်အထက်' },
  { value: 'prefer_not', label: 'မပြောလိုပါ' },
]
const skinToneOptions = ['#f7e7d3', '#efd2b1', '#e3bc91', '#c9976b', '#ad754e', '#8c593b', '#70432f', '#553122', '#3d2319', '#291711']
const skinGoalOptions = [
  { value: 'acne', label: 'ဝက်ခြံ' },
  { value: 'redness', label: 'နီမြန်းမှု' },
  { value: 'pigmentation', label: 'အမည်းစက်' },
  { value: 'texture', label: 'အသားအရေ မညီညာမှု' },
  { value: 'oiliness', label: 'အဆီပြန်မှု' },
  { value: 'dryness', label: 'ခြောက်သွေ့မှု' },
]

const workspaceModules = computed(() => [
  { key: 'scan', title: 'မျက်နှာ စကင်', subtitle: 'ကင်မရာဖြင့် အသားအရေကို စစ်ဆေးပါ', meta: 'စကင် စမယ်', icon: scanIcon, accent: '#f36a16' },
  { key: 'routine', title: 'နေ့စဉ် ထိန်းသိမ်းမှု', subtitle: routine.value ? `ဒီနေ့ ${todayProgress.value}% ပြီးစီး` : 'စကင်ရလဒ်မှ အစီအစဉ် စတင်ပါ', meta: routine.value ? 'ဆက်လုပ်မယ်' : 'မစတင်ရသေး', icon: routineIcon, accent: '#0e5c56' },
  { key: 'history', title: 'စကင် မှတ်တမ်း', subtitle: `သိမ်းထားသော ရလဒ် ${history.value.length} ခု`, meta: 'တိုးတက်မှုကြည့်မယ်', icon: historyIcon, accent: '#c67d32' },
  { key: 'safety', title: 'အကူအညီနှင့် လုံခြုံမှု', subtitle: 'Privacy၊ consent နှင့် AI အသုံးပြုပုံကို ထိန်းချုပ်ပါ', meta: 'သင့်ရွေးချယ်မှု', icon: calmMascot, accent: '#0e5c56' },
  { key: 'appointment', title: 'ကျွမ်းကျင်သူ အကူအညီ', subtitle: 'ရလဒ်ကို ကျွမ်းကျင်သူထံ ပို့ပါ', meta: latestResult.value ? 'တောင်းဆိုနိုင်ပြီ' : 'စကင်လိုအပ်သည်', icon: specialistIcon, accent: '#38748f' },
])
const currentViewTitle = computed(() => ({
  home: 'ပင်မ စာမျက်နှာ', profile: 'ကိုယ်ရေးအချက်အလက်', safety: 'အကူအညီနှင့် လုံခြုံမှု', scan: 'မျက်နှာ စကင်', result: 'စကင် ရလဒ်', routine: 'နေ့စဉ် ထိန်းသိမ်းမှု', history: 'စကင် မှတ်တမ်း', appointment: 'ကျွမ်းကျင်သူ အကူအညီ',
})[activeView.value] || 'Skino အလုပ်နေရာ')

let faceDetector = null
let faceLandmarker = null
let detectorMode = 'IMAGE'
let landmarkerMode = 'IMAGE'
let detectionFrame = 0
let lastDetectionAt = 0
let lastLandmarkAt = 0
let faceStableSince = 0
const latestFaceLandmarks = ref([])
const latestFacePose = ref(null)
const MEDIAPIPE_WASM_URL = 'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@1.0.1/wasm'
const FACE_MODEL_URL = 'https://storage.googleapis.com/mediapipe-models/face_detector/blaze_face_short_range/float16/latest/blaze_face_short_range.tflite'
const FACE_LANDMARK_MODEL_URL = 'https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/latest/face_landmarker.task'
const DEBUG_ZONE_POLYGONS = {
  forehead: [127, 34, 139, 71, 68, 104, 69, 108, 10, 337, 299, 333, 298, 301, 368, 264, 356, 300, 293, 334, 296, 336, 107, 66, 105, 63, 70],
  left_cheek: [50, 101, 205, 187, 123, 116, 111, 117, 118, 119, 100, 36, 206, 216, 212, 202],
  right_cheek: [280, 330, 425, 411, 352, 345, 340, 346, 347, 348, 329, 266, 426, 436, 432, 422],
  nose: [168, 6, 197, 195, 5, 4, 45, 220, 115, 48, 64, 98, 97, 2, 326, 327, 294, 278, 344, 440, 275],
  chin: [61, 185, 40, 39, 37, 0, 267, 269, 270, 409, 291, 375, 321, 405, 314, 17, 84, 181, 91, 146],
}
const DEBUG_ZONE_COLORS = {
  forehead: '#f59e0b', left_cheek: '#22c55e', right_cheek: '#38bdf8', nose: '#a78bfa', chin: '#fb7185',
}
const zoneOverlayPolygons = computed(() => Object.entries(DEBUG_ZONE_POLYGONS).map(([key, indices]) => {
  const points = indices.map((index) => latestFaceLandmarks.value[index]).filter(Boolean)
  const signal = latestResult.value?.skin_zones?.find((zone) => zone.key === key)
  return {
    key,
    color: DEBUG_ZONE_COLORS[key],
    points: points.map((point) => `${point.x * 100},${point.y * 100}`).join(' '),
    x: points.length ? (points.reduce((sum, point) => sum + point.x, 0) / points.length) * 100 : 0,
    y: points.length ? (points.reduce((sum, point) => sum + point.y, 0) / points.length) * 100 : 0,
    signal,
  }
}).filter((zone) => zone.points))

const specialistProfiles = [
  { name: 'Dr. May Thandar', role: 'Acne and sensitive skin', schedule: 'Mon, Wed, Fri', tone: 'bg-skino-orange-soft text-skino-orange-dark' },
  { name: 'Dr. Htet Aung', role: 'Dark spots and texture', schedule: 'Tue, Thu', tone: 'bg-emerald-50 text-skino-green' },
  { name: 'Dr. Ei Mon', role: 'Routine review', schedule: 'Weekend follow-up', tone: 'bg-[#eef1eb] text-[#5d7056]' },
]

async function loadWorkspace() {
  pageLoading.value = true
  error.value = ''
  loadErrors.value = {}
  const [historyResult, routineResult, profileResult] = await Promise.allSettled([
    fetchScanHistory(token.value),
    fetchRoutine(token.value),
    fetchProfile(token.value),
  ])
  if (historyResult.status === 'fulfilled') history.value = historyResult.value
  else loadErrors.value.history = historyResult.reason.message
  if (routineResult.status === 'fulfilled') routine.value = routineResult.value
  else loadErrors.value.routine = routineResult.reason.message
  if (profileResult.status === 'fulfilled') setProfile(profileResult.value)
  else loadErrors.value.profile = profileResult.reason.message
  pageLoading.value = false
}

async function retryWorkspaceSection(section) {
  if (retryingSection.value) return
  retryingSection.value = section
  loadErrors.value = { ...loadErrors.value, [section]: '' }
  try {
    if (section === 'history') history.value = await fetchScanHistory(token.value)
    if (section === 'routine') routine.value = await fetchRoutine(token.value)
    if (section === 'profile') setProfile(await fetchProfile(token.value))
  } catch (retryError) {
    loadErrors.value = { ...loadErrors.value, [section]: retryError.message }
  } finally {
    retryingSection.value = ''
  }
}

function setProfile(nextProfile) {
  profile.value = nextProfile
  profileForm.value = {
    name: nextProfile?.name || '',
    age_band: nextProfile?.age_band || '',
    skin_tone_scale: nextProfile?.skin_tone_scale || null,
    skin_goals: [...(nextProfile?.skin_goals || [])],
  }
}

function openProfile() {
  profileOpen.value = false
  openView('profile')
}

function toggleSkinGoal(goal) {
  const goals = profileForm.value.skin_goals
  profileForm.value.skin_goals = goals.includes(goal)
    ? goals.filter((item) => item !== goal)
    : goals.length < 5 ? [...goals, goal] : goals
}

async function saveProfile() {
  if (!profileForm.value.name.trim() || profileSaving.value) return
  profileSaving.value = true
  error.value = ''
  try {
    const updated = await updateProfile(token.value, {
      name: profileForm.value.name.trim(),
      age_band: profileForm.value.age_band || null,
      skin_tone_scale: profileForm.value.skin_tone_scale || null,
      skin_goals: profileForm.value.skin_goals,
    })
    setProfile(updated)
    emit('profile-updated', updated)
    notice.value = 'ကိုယ်ရေးအချက်အလက်ကို သိမ်းပြီးပါပြီ။'
  } catch (profileError) {
    error.value = profileError.message
  } finally {
    profileSaving.value = false
  }
}

async function saveTrainingChoice() {
  if (profileSaving.value) return
  profileSaving.value = true
  error.value = ''
  try {
    const consent = await updateTrainingConsent(token.value, localTrainingConsent.value)
    emit('training-consent-updated', consent.granted === true)
    notice.value = consent.granted
      ? 'AI တိုးတက်ရေးအတွက် သဘောတူညီချက်ကို သိမ်းပြီးပါပြီ။'
      : 'နောက်ထပ်စကင်များကို AI လေ့ကျင့်ရေးတွင် မသုံးရန် ပြင်ဆင်ပြီးပါပြီ။'
  } catch (consentError) {
    localTrainingConsent.value = props.allowModelTraining
    error.value = consentError.message
  } finally {
    profileSaving.value = false
  }
}

function openView(view) {
  if (view !== 'scan') stopCamera()
  pricingOpen.value = false
  activeView.value = view
  error.value = ''
  notice.value = ''
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

function openAppointment(analysis = latestResult.value) {
  if (!analysis?.id) {
    openView('scan')
    notice.value = 'Complete a scan before requesting a specialist appointment.'
    return
  }
  result.value = analysis
  appointmentScanId.value = String(analysis.id)
  appointmentSuccess.value = null
  appointmentForm.value = {
    ...appointmentForm.value,
    name: user.value.name || '',
    email: user.value.email || '',
    preferredContactMethod: 'in_app',
    beautyGoal: ['moderate', 'severe'].includes(analysis.acne_severity)
      ? 'Specialist acne consultation'
      : 'Routine review with specialist',
  }
  openView('appointment')
}

function concernSummary(scan) {
  if (!scan?.concerns?.length) return 'Latest scan found no strong visible concern.'
  return scan.concerns.map((concern) => {
    const confidence = Math.round(Number(concern.confidence || 0) * 100)
    return `${concern.name} ${confidence}% ${concern.severity || ''}`.trim()
  }).join(', ')
}

async function submitAppointment() {
  const scan = selectedAppointmentScan.value
  if (!scan?.id || appointmentLoading.value) return
  if (!appointmentForm.value.phone.trim() && !appointmentForm.value.email.trim()) {
    error.value = 'Add a phone number or email so the team can contact you.'
    return
  }
  appointmentLoading.value = true
  error.value = ''
  try {
    appointmentSuccess.value = await createAppointmentRequest(token.value, {
      name: appointmentForm.value.name.trim(),
      email: appointmentForm.value.email.trim(),
      phone: appointmentForm.value.phone.trim(),
      preferred_contact_method: appointmentForm.value.preferredContactMethod,
      ...(appointmentForm.value.preferredDate ? { preferred_date: appointmentForm.value.preferredDate } : {}),
      requested_specialist: appointmentForm.value.requestedSpecialist,
      beauty_goal: appointmentForm.value.beautyGoal.trim(),
      notes: appointmentForm.value.notes.trim(),
      skin_analysis_id: scan.id,
      skin_type: scan.skin_type,
      acne_severity: scan.acne_severity,
      skin_health_score: scan.skin_health_score,
      concern_summary: concernSummary(scan),
    })
    notice.value = 'Appointment request sent. The Skino team can follow up from CRM.'
    window.scrollTo({ top: 0, behavior: 'smooth' })
  } catch (appointmentError) {
    error.value = appointmentError.message
  } finally {
    appointmentLoading.value = false
  }
}

function openModule(module) {
  if (module.key === 'appointment') {
    openAppointment()
    return
  }
  openView(module.key)
}

function strongestZoneSignal(zone) {
  return [
    ['Oil', Number(zone.oiliness || 0), '#f36a16'],
    ['Dark spots', Number(zone.dark_spots || 0), '#8e6deb'],
    ['Redness', Number(zone.redness || 0), '#e95d48'],
    ['Texture', Number(zone.texture || 0), '#0e5c56'],
    ['Dryness', Number(zone.dryness || 0), '#7a8f72'],
  ].sort((a, b) => b[1] - a[1])[0]
}

function zoneMarkerStyle(zone) {
  const positions = {
    forehead: ['50%', '18%'],
    left_cheek: ['30%', '48%'],
    right_cheek: ['70%', '48%'],
    nose: ['50%', '48%'],
    chin: ['50%', '78%'],
  }
  const [left, top] = positions[zone.key] || ['50%', '50%']
  const signal = strongestZoneSignal(zone)
  return { left, top, backgroundColor: signal[2], boxShadow: `0 0 0 5px ${signal[2]}2b` }
}

function metricPercent(value) {
  return `${Math.round(Number(value || 0) * 100)}%`
}

function skinTypeMy(value) {
  return ({ normal: 'ပုံမှန်အသားအရေ', oily: 'အဆီပြန်အသားအရေ', dry: 'ခြောက်သွေ့အသားအရေ', combination: 'ပေါင်းစပ်အသားအရေ', sensitive: 'ထိခိုက်လွယ်အသားအရေ' })[value] || 'အသားအရေ အမျိုးအစား'
}

function severityMy(value) {
  return ({ none: 'မတွေ့ရှိပါ', low: 'အလွန်နည်း', mild: 'အနည်းငယ်', moderate: 'အသင့်အတင့်', severe: 'ပြင်းထန်' })[value] || 'အနည်းငယ်'
}

function concernMy(value) {
  return ({ acne: 'ဝက်ခြံ', redness: 'နီမြန်းမှု', dark_spots: 'အမည်းစက်', oiliness: 'အဆီပြန်မှု', dryness: 'ခြောက်သွေ့မှု', texture: 'အသားအရေ မညီညာမှု', pores: 'ချွေးပေါက်ကျယ်မှု' })[value] || String(value || '').replaceAll('_', ' ')
}

function zoneNameMy(zone) {
  return ({ forehead: 'နဖူး', left_cheek: 'ဘယ်ဘက်ပါး', right_cheek: 'ညာဘက်ပါး', nose: 'နှာခေါင်း', chin: 'မေးစေ့' })[zone?.key] || zone?.label || 'မျက်နှာ Zone'
}

function concernPalette(name) {
  return ({
    acne: { background: '#fff0e8', color: '#b84612', bar: '#f36a16' },
    redness: { background: '#fff0ef', color: '#a33d35', bar: '#e95d48' },
    dark_spots: { background: '#f3efff', color: '#604a9b', bar: '#8068c0' },
    oiliness: { background: '#fff7df', color: '#8a6419', bar: '#d79a24' },
    dryness: { background: '#edf7f2', color: '#246653', bar: '#3f9276' },
    texture: { background: '#eef5f4', color: '#185f59', bar: '#0e5c56' },
  })[String(name || '').toLowerCase()] || { background: '#fff4e8', color: '#8e4d25', bar: '#f36a16' }
}

function routineStepMy(step) {
  const value = String(step || '').toLowerCase()
  if (value.includes('cleanser') || value.includes('clean')) return 'နူးညံ့သော မျက်နှာသစ်ဆေးဖြင့် သန့်စင်ပါ'
  if (value.includes('serum')) return 'အသားအရေကြည်လင် အားဖြည့်ရည်ကို ၂–၃ စက် လိမ်းပါ'
  if (value.includes('moistur')) return 'အစိုဓာတ်ထိန်း ခရင်မ် လိမ်းပါ'
  if (value.includes('sun') || value.includes('spf')) return 'နေရောင်ကာ လိမ်းဆေးကို မနက်တိုင်း လိမ်းပါ'
  if (value.includes('spot')) return 'လိုအပ်သော နေရာကိုသာ သီးသန့်ထိန်းသိမ်းပါ'
  return 'နူးညံ့သော နေ့စဉ်ထိန်းသိမ်းမှု အဆင့်ကို လိုက်နာပါ'
}

function routineTaskDone(group, task) {
  const saved = routine.value?.today?.[`${group.key}_steps`] || []
  if (saved.length) return saved.includes(task.key) || saved.includes(task.legacyKey)
  return Boolean(routine.value?.today?.[`${group.key}_done`])
}

async function toggleRoutineTask(group, task) {
  if (!routine.value || loading.value) return
  if (routineTaskDone(group, task)) {
    notice.value = 'ပြီးစီးထားသော ဒီနေ့လုပ်ဆောင်ချက်ကို ပြန်ဖြုတ်၍ မရပါ။'
    return
  }
  const field = `${group.key}_steps`
  const doneField = `${group.key}_done`
  const saved = routine.value.today?.[field] || []
  const current = saved.length ? [...saved] : (routine.value.today?.[doneField] ? group.tasks.map((item) => item.key) : [])
  const next = [...current, task.key]
  loading.value = true
  error.value = ''
  try {
    routine.value = await updateRoutineToday(token.value, {
      [field]: next,
      [doneField]: group.tasks.every((item) => next.includes(item.key)),
    })
  } catch (routineError) {
    error.value = routineError.message
  } finally {
    loading.value = false
  }
}

async function ensureFaceDetector() {
  if (faceDetector) return faceDetector
  const vision = await FilesetResolver.forVisionTasks(MEDIAPIPE_WASM_URL)
  faceDetector = await FaceDetector.createFromOptions(vision, {
    baseOptions: { modelAssetPath: FACE_MODEL_URL },
    runningMode: 'IMAGE',
    minDetectionConfidence: 0.68,
    minSuppressionThreshold: 0.3,
  })
  detectorMode = 'IMAGE'
  return faceDetector
}

async function setDetectorMode(mode) {
  const detector = await ensureFaceDetector()
  if (detectorMode !== mode) {
    await detector.setOptions({ runningMode: mode })
    detectorMode = mode
  }
  return detector
}

async function ensureFaceLandmarker() {
  if (faceLandmarker) return faceLandmarker
  const vision = await FilesetResolver.forVisionTasks(MEDIAPIPE_WASM_URL)
  faceLandmarker = await FaceLandmarker.createFromOptions(vision, {
    baseOptions: { modelAssetPath: FACE_LANDMARK_MODEL_URL },
    runningMode: 'IMAGE',
    numFaces: 1,
    minFaceDetectionConfidence: 0.65,
    minFacePresenceConfidence: 0.65,
    minTrackingConfidence: 0.65,
    outputFacialTransformationMatrixes: true,
  })
  landmarkerMode = 'IMAGE'
  return faceLandmarker
}

async function setLandmarkerMode(mode) {
  const landmarker = await ensureFaceLandmarker()
  if (landmarkerMode !== mode) {
    await landmarker.setOptions({ runningMode: mode })
    landmarkerMode = mode
  }
  return landmarker
}

function facePoseFromResult(landmarkResult) {
  const matrix = landmarkResult?.facialTransformationMatrixes?.[0]
  const values = Array.from(matrix?.data || matrix || [])
  if (values.length < 16) return null
  const toDegrees = (value) => value * (180 / Math.PI)
  const pitch = toDegrees(Math.atan2(values[9], values[10]))
  const yaw = toDegrees(Math.atan2(-values[8], Math.sqrt((values[9] ** 2) + (values[10] ** 2))))
  const roll = toDegrees(Math.atan2(values[4], values[0]))
  return { pitch: Number(pitch.toFixed(1)), yaw: Number(yaw.toFixed(1)), roll: Number(roll.toFixed(1)) }
}

function updateLandmarkState(landmarkResult, mirrorX = false) {
  latestFaceLandmarks.value = (landmarkResult?.faceLandmarks?.[0] || []).map((point) => ({
    x: Number((mirrorX ? 1 - point.x : point.x).toFixed(6)),
    y: Number(point.y.toFixed(6)),
    z: Number((point.z || 0).toFixed(6)),
  }))
  latestFacePose.value = facePoseFromResult(landmarkResult)
}

function assessFace(detectionResult, width, height, pose = latestFacePose.value) {
  const detections = detectionResult?.detections || []
  if (detections.length === 0) return { state: 'no-face', message: 'မျက်နှာ မတွေ့ပါ။ ကင်မရာကို တည့်တည့်ကြည့်ပြီး အလင်းရောင် ပြင်ပါ။', confidence: 0 }
  if (detections.length > 1) return { state: 'multiple', message: 'မျက်နှာညှိကွက်အတွင်း လူတစ်ယောက်တည်းသာ ရှိပါစေ။', confidence: 0 }

  const detection = detections[0]
  const box = detection.boundingBox || {}
  const originX = Number(box.originX ?? box.origin_x ?? 0)
  const originY = Number(box.originY ?? box.origin_y ?? 0)
  const boxWidth = Number(box.width || 0)
  const boxHeight = Number(box.height || 0)
  const widthRatio = boxWidth / Math.max(width, 1)
  const heightRatio = boxHeight / Math.max(height, 1)
  const centerX = (originX + boxWidth / 2) / Math.max(width, 1)
  const centerY = (originY + boxHeight / 2) / Math.max(height, 1)
  const confidence = Math.round(Number(detection.categories?.[0]?.score || 0) * 100)

  if (confidence < 65) return { state: 'unclear', message: 'မျက်နှာ မကြည်လင်သေးပါ။ အလင်းရောင်ကောင်းသောနေရာတွင် ခဏငြိမ်နေပါ။', confidence }
  if (widthRatio < 0.27 || heightRatio < 0.33) return { state: 'too-small', message: 'မျက်နှာကို frame အတွင်း ပြည့်စေရန် ကင်မရာနား နည်းနည်းတိုးပါ။', confidence }
  if (widthRatio > 0.86 || heightRatio > 0.93) return { state: 'too-close', message: 'မျက်နှာတစ်ခုလုံး မြင်ရအောင် နည်းနည်း နောက်ဆုတ်ပါ။', confidence }
  if (Math.abs(centerX - 0.5) > 0.17 || Math.abs(centerY - 0.49) > 0.18) return { state: 'off-center', message: 'မျက်နှာကို ညှိကွက်အတွင်း နည်းနည်းရွှေ့ပါ။', confidence }

  const eyes = detection.keypoints?.slice(0, 2) || []
  if (eyes.length === 2 && Math.abs(Number(eyes[0].y) - Number(eyes[1].y)) > 0.065) {
    return { state: 'tilted', message: 'ခေါင်းကို တည့်တည့်ထားပြီး မျက်လုံးနှစ်ဖက် ညီအောင်ထားပါ။', confidence }
  }
  if (pose && (Math.abs(pose.yaw) > 14 || Math.abs(pose.pitch) > 13 || Math.abs(pose.roll) > 10)) {
    return { state: 'pose', message: 'မျက်နှာကို ကင်မရာဘက် တည့်တည့်လှည့်ပြီး ခေါင်းကို မငုံ့/မော့ဘဲထားပါ။', confidence }
  }
  return { state: 'good', message: 'အဆင်သင့်ပါပြီ။ ခဏငြိမ်နေပြီး ဓာတ်ပုံရိုက်ပါ။', confidence }
}

async function beginFaceGuidance() {
  faceGuide.value = { state: 'loading', message: 'မျက်နှာအနေအထား စစ်ဆေးနေသည်…', confidence: 0 }
  try {
    const detector = await setDetectorMode('VIDEO')
    let landmarker = null
    try { landmarker = await setLandmarkerMode('VIDEO') } catch { landmarker = null }
    const detectFrame = () => {
      if (!cameraActive.value || !video.value) return
      const now = performance.now()
      if (video.value.readyState >= 2 && now - lastDetectionAt > 160) {
        lastDetectionAt = now
        try {
          const detectionResult = detector.detectForVideo(video.value, now)
          const initialAssessment = assessFace(detectionResult, video.value.videoWidth, video.value.videoHeight)
          if (landmarker && initialAssessment.confidence >= 65 && now - lastLandmarkAt > 320) {
            lastLandmarkAt = now
            const landmarkResult = landmarker.detectForVideo(video.value, now)
            updateLandmarkState(landmarkResult, true)
          }
          const assessment = assessFace(detectionResult, video.value.videoWidth, video.value.videoHeight)
          if (assessment.state === 'good') {
            if (!faceStableSince) faceStableSince = now
            faceGuide.value = now - faceStableSince >= 320
              ? assessment
              : { state: 'stabilizing', message: 'အနေအထားမှန်ပါပြီ။ တိကျသောပုံရရန် ခဏငြိမ်နေပါ…', confidence: assessment.confidence }
          } else {
            faceStableSince = 0
            faceGuide.value = assessment
          }
        } catch {
          faceGuide.value = { state: 'unavailable', message: 'အလိုအလျောက် စစ်ဆေးမှု ခေတ္တရပ်နေသည်။ မျက်နှာညှိကွက်ကို အသုံးပြုပါ။', confidence: 0 }
        }
      }
      detectionFrame = requestAnimationFrame(detectFrame)
    }
    detectionFrame = requestAnimationFrame(detectFrame)
  } catch {
    faceGuide.value = { state: 'unavailable', message: 'မျက်နှာစစ်ဆေးမှု မဖွင့်နိုင်ပါ။ မျက်နှာညှိကွက်ဖြင့် ဆက်ရိုက်နိုင်သည်။', confidence: 0 }
  }
}

async function validateUploadedFace(file) {
  faceGuide.value = { state: 'loading', message: 'ရွေးထားသောပုံတွင် မျက်နှာတစ်ခု ရှင်းလင်းစွာပါရှိကြောင်း စစ်နေသည်…', confidence: 0 }
  inputValidated.value = false
  try {
    const image = new Image()
    image.src = URL.createObjectURL(file)
    try {
      await image.decode()
      const detector = await setDetectorMode('IMAGE')
      const detectionResult = detector.detect(image)
      try {
        const landmarker = await setLandmarkerMode('IMAGE')
        updateLandmarkState(landmarker.detect(image))
      } catch {
        latestFaceLandmarks.value = []
        latestFacePose.value = null
      }
      faceGuide.value = assessFace(detectionResult, image.naturalWidth, image.naturalHeight)
      inputValidated.value = faceGuide.value.state === 'good'
    } finally {
      URL.revokeObjectURL(image.src)
    }
  } catch {
    faceGuide.value = { state: 'unavailable', message: 'အလိုအလျောက် စစ်ဆေးမှု မရနိုင်ပါ။ စနစ်မှ ပုံအရည်အသွေး ဆက်စစ်ပါမည်။', confidence: 0 }
    inputValidated.value = true
  }
}

async function startCamera() {
  error.value = ''
  inputValidated.value = false
  latestFaceLandmarks.value = []
  latestFacePose.value = null
  capturedFrames.value = []
  if (!cameraSupported.value) {
    error.value = 'ဤဝဘ်ဘရောက်ဇာတွင် ကင်မရာအသုံးပြု၍ မရပါ။ ဓာတ်ပုံတင်ပြီး ဆက်လုပ်ပါ။'
    return
  }
  stopCamera()
  try {
    stream.value = await navigator.mediaDevices.getUserMedia({
      video: { facingMode: 'user', width: { ideal: 1280 }, height: { ideal: 1280 } },
      audio: false,
    })
    cameraActive.value = true
    await nextTick()
    video.value.srcObject = stream.value
    await video.value.play()
    beginFaceGuidance()
  } catch (cameraError) {
    error.value = cameraError.name === 'NotAllowedError'
      ? 'ကင်မရာခွင့်ပြုချက် မရပါ။ ဝဘ်ဘရောက်ဇာဆက်တင်တွင် ခွင့်ပြုပါ သို့မဟုတ် ဓာတ်ပုံတင်ပါ။'
      : 'ကင်မရာဖွင့်မရပါ။ အခြား camera app များပိတ်ပြီး ပြန်စမ်းပါ။'
  }
}

function stopCamera() {
  if (detectionFrame) cancelAnimationFrame(detectionFrame)
  detectionFrame = 0
  faceStableSince = 0
  stream.value?.getTracks().forEach((track) => track.stop())
  stream.value = null
  cameraActive.value = false
  if (video.value) video.value.srcObject = null
}

function replacePreview(file, validated = false) {
  if (previewUrl.value) URL.revokeObjectURL(previewUrl.value)
  capturedFile.value = file
  previewUrl.value = URL.createObjectURL(file)
  inputValidated.value = validated
}

function frameQuality(context, width, height) {
  const sample = document.createElement('canvas')
  sample.width = 160
  sample.height = 160
  const sampleContext = sample.getContext('2d', { willReadFrequently: true })
  sampleContext.drawImage(context.canvas, 0, 0, width, height, 0, 0, 160, 160)
  const pixels = sampleContext.getImageData(0, 0, 160, 160).data
  const luminance = []
  let total = 0
  for (let index = 0; index < pixels.length; index += 4) {
    const value = (pixels[index] * 0.299) + (pixels[index + 1] * 0.587) + (pixels[index + 2] * 0.114)
    luminance.push(value)
    total += value
  }
  const mean = total / luminance.length
  const variance = luminance.reduce((sum, value) => sum + ((value - mean) ** 2), 0) / luminance.length
  let edgeTotal = 0
  let edgeCount = 0
  for (let y = 1; y < 159; y += 2) {
    for (let x = 1; x < 159; x += 2) {
      const index = (y * 160) + x
      edgeTotal += Math.abs((luminance[index] * 4) - luminance[index - 1] - luminance[index + 1] - luminance[index - 160] - luminance[index + 160])
      edgeCount += 1
    }
  }
  const brightness = Math.max(0, 100 - (Math.abs(mean - 145) / 1.25))
  const contrast = Math.min(100, Math.sqrt(variance) * 2.2)
  const sharpness = Math.min(100, (edgeTotal / Math.max(edgeCount, 1)) * 2.8)
  return Math.round((brightness * 0.35) + (contrast * 0.2) + (sharpness * 0.45))
}

function canvasBlob(output) {
  return new Promise((resolve) => output.toBlob(resolve, 'image/jpeg', 0.95))
}

function wait(milliseconds) {
  return new Promise((resolve) => window.setTimeout(resolve, milliseconds))
}

async function captureFrame() {
  const source = video.value
  const output = canvas.value
  if (!source?.videoWidth || !output || !canCapture.value || capturingFrames.value) return
  capturingFrames.value = true
  captureProgress.value = 0
  const size = Math.min(source.videoWidth, source.videoHeight)
  const x = (source.videoWidth - size) / 2
  const y = (source.videoHeight - size) / 2
  output.width = 1280
  output.height = 1280
  const context = output.getContext('2d')
  const candidates = []
  try {
    for (let frame = 1; frame <= 3; frame += 1) {
      context.save()
      context.translate(1280, 0)
      context.scale(-1, 1)
      context.drawImage(source, x, y, size, size, 0, 0, 1280, 1280)
      context.restore()
      const quality = frameQuality(context, 1280, 1280)
      const blob = await canvasBlob(output)
      if (blob) candidates.push({ blob, quality })
      captureProgress.value = frame
      if (frame < 3) await wait(100)
    }
    const best = candidates.sort((a, b) => b.quality - a.quality)[0]
    if (!best) throw new Error('No frame captured')
    captureQualityScore.value = best.quality
    captureMode.value = 'multi_frame_median'
    latestFaceLandmarks.value = latestFaceLandmarks.value.map((point) => ({
      x: Number(Math.min(1.15, Math.max(-0.15, ((point.x * source.videoWidth) - x) / size)).toFixed(6)),
      y: Number(Math.min(1.15, Math.max(-0.15, ((point.y * source.videoHeight) - y) / size)).toFixed(6)),
      z: point.z,
    }))
    capturedFrames.value = candidates.map((candidate, index) => new File(
      [candidate.blob],
      `skino-frame-${index + 1}-${Date.now()}.jpg`,
      { type: 'image/jpeg' },
    ))
    replacePreview(capturedFrames.value[0], true)
    faceGuide.value = { state: 'good', message: `ပုံ ၃ ပုံကို အလယ်တန်ဖိုးဖြင့် နှိုင်းယှဉ်ရန် အဆင်သင့်ပါပြီ · ${best.quality}%`, confidence: faceGuide.value.confidence }
    stopCamera()
  } catch {
    error.value = 'ပုံများကို ဆက်တိုက်ရိုက်ယူ၍ မရပါ။ ကင်မရာကို ပြန်ဖွင့်ပြီး စမ်းပါ။'
  } finally {
    capturingFrames.value = false
  }
}

async function chooseFile(event) {
  const file = event.target.files?.[0]
  if (!file) return
  if (!file.type.startsWith('image/')) {
    error.value = 'JPG၊ PNG သို့မဟုတ် WebP ပုံကို ရွေးပါ။'
    return
  }
  if (file.size > 8 * 1024 * 1024) {
    error.value = 'ပုံအရွယ်အစားသည် 8 MB အောက် ဖြစ်ရပါမည်။'
    return
  }
  replacePreview(file)
  capturedFrames.value = []
  captureMode.value = 'single_upload'
  captureProgress.value = 1
  captureQualityScore.value = 0
  stopCamera()
  error.value = ''
  await validateUploadedFace(file)
}

function retake() {
  capturedFile.value = null
  inputValidated.value = false
  if (previewUrl.value) URL.revokeObjectURL(previewUrl.value)
  previewUrl.value = ''
  faceGuide.value = { state: 'idle', message: 'ကင်မရာဖွင့်ပြီး မျက်နှာတစ်ခုလုံးကို frame အတွင်းထားပါ။', confidence: 0 }
  latestFaceLandmarks.value = []
  latestFacePose.value = null
  capturedFrames.value = []
  captureProgress.value = 0
  captureQualityScore.value = 0
  captureMode.value = 'single_upload'
  startCamera()
}

function deviceCategory() {
  const width = window.innerWidth
  if (width < 768) return 'mobile'
  if (width < 1100) return 'tablet'
  return 'desktop'
}

function stopAnalysisProgress() {
  window.clearInterval(analysisProgressTimer)
  analysisProgressTimer = null
}

function startAnalysisProgress() {
  stopAnalysisProgress()
  analysisProgress.value = 7
  analysisStageIndex.value = 0
  const startedAt = Date.now()
  analysisProgressTimer = window.setInterval(() => {
    const elapsed = Date.now() - startedAt
    const ceiling = elapsed < 2500 ? 30 : elapsed < 7000 ? 58 : elapsed < 15000 ? 78 : 92
    const step = analysisProgress.value < 45 ? 3 : analysisProgress.value < 75 ? 2 : 1
    analysisProgress.value = Math.min(ceiling, analysisProgress.value + step)
    analysisStageIndex.value = analysisProgress.value >= 78 ? 3 : analysisProgress.value >= 50 ? 2 : analysisProgress.value >= 24 ? 1 : 0
  }, 520)
}

async function submitScan() {
  if (!canAnalyze.value || !online.value) return
  analysisController?.abort()
  analysisController = new AbortController()
  loading.value = true
  scanFailure.value = ''
  error.value = ''
  notice.value = 'ပုံအရည်အသွေးနှင့် မြင်နိုင်သော အသားအရေအချက်များကို စစ်ဆေးနေသည်…'
  startAnalysisProgress()
  try {
    result.value = await analyzeSkin(token.value, capturedFile.value, localTrainingConsent.value, {
      mode: captureMode.value,
      frameCount: captureProgress.value || 1,
      qualityScore: captureQualityScore.value,
      deviceCategory: deviceCategory(),
      landmarks: latestFaceLandmarks.value,
      frames: capturedFrames.value.slice(1),
    }, analysisController.signal)
    stopAnalysisProgress()
    analysisStageIndex.value = analysisStages.length - 1
    analysisProgress.value = 100
    await new Promise((resolve) => window.setTimeout(resolve, 260))
    history.value = [result.value, ...history.value.filter((item) => item.id !== result.value.id)]
    activeView.value = 'result'
    notice.value = ''
    window.scrollTo({ top: 0 })
  } catch (scanError) {
    stopAnalysisProgress()
    if (scanError.code !== 'CANCELLED') {
      scanFailure.value = scanError.message
      error.value = scanError.message
    }
    notice.value = ''
  } finally {
    stopAnalysisProgress()
    loading.value = false
    analysisController = null
  }
}

function cancelAnalysis() {
  analysisController?.abort()
  stopAnalysisProgress()
  notice.value = 'စစ်ဆေးမှုကို ရပ်လိုက်ပါပြီ။ ရွေးထားသောဓာတ်ပုံကို မဖျက်ထားပါ။'
}

function syncOnlineState() {
  online.value = navigator.onLine
  if (!online.value) error.value = 'အင်တာနက်ချိတ်ဆက်မှု မရှိပါ။ ပုံကိုသိမ်းထားပြီး ချိတ်ဆက်ပြီးနောက် ပြန်စမ်းနိုင်သည်။'
  else if (error.value.includes('အင်တာနက်ချိတ်ဆက်မှု')) error.value = ''
}

async function activateRoutine(analysis = latestResult.value) {
  if (!analysis?.id) return
  loading.value = true
  error.value = ''
  try {
    routine.value = await startRoutine(token.value, analysis.id)
    notice.value = 'သင့်နေ့စဉ် routine ကို စတင်ပြီးပါပြီ။'
    activeView.value = 'routine'
  } catch (routineError) {
    error.value = routineError.message
  } finally {
    loading.value = false
  }
}

async function toggleRoutine(field) {
  if (!routine.value || loading.value) return
  loading.value = true
  error.value = ''
  try {
    routine.value = await updateRoutineToday(token.value, { [field]: !routine.value.today[field] })
  } catch (routineError) {
    error.value = routineError.message
  } finally {
    loading.value = false
  }
}

async function deactivateRoutine() {
  if (!routine.value || !window.confirm('Stop this active routine? Your scan history will stay saved.')) return
  loading.value = true
  try {
    await stopRoutine(token.value)
    routine.value = null
    notice.value = 'Routine stopped.'
  } catch (routineError) {
    error.value = routineError.message
  } finally {
    loading.value = false
  }
}

function viewHistoryItem(item) {
  result.value = item
  activeView.value = 'result'
  window.scrollTo({ top: 0 })
}

async function removeHistoryItem(item) {
  if (!window.confirm('Delete this saved scan? This cannot be undone.')) return
  loading.value = true
  try {
    await deleteScan(token.value, item.id)
    history.value = history.value.filter((entry) => entry.id !== item.id)
    if (result.value?.id === item.id) result.value = null
  } catch (deleteError) {
    error.value = deleteError.message
  } finally {
    loading.value = false
  }
}

function formatDate(value) {
  if (!value) return 'လတ်တလော စကင်'
  const date = new Date(value)
  return `${date.getFullYear()} ခုနှစ် ${date.getMonth() + 1} လ ${date.getDate()} ရက်`
}

watch(activeView, (view) => { if (view !== 'scan') stopCamera() })
watch(() => props.allowModelTraining, (granted) => { localTrainingConsent.value = granted })
onMounted(() => {
  window.addEventListener('online', syncOnlineState)
  window.addEventListener('offline', syncOnlineState)
  loadWorkspace()
})
onUnmounted(() => {
  analysisController?.abort()
  stopAnalysisProgress()
  window.removeEventListener('online', syncOnlineState)
  window.removeEventListener('offline', syncOnlineState)
  stopCamera()
  if (previewUrl.value) URL.revokeObjectURL(previewUrl.value)
})
</script>

<template>
  <main class="workspace-shell min-h-screen bg-[radial-gradient(circle_at_top_right,rgba(243,106,22,.07),transparent_30%)] bg-skino-cream px-3 pt-2 text-skino-ink sm:px-5 lg:px-8" :class="activeView === 'scan' ? 'pb-1 lg:h-screen lg:overflow-hidden' : 'pb-12'">
    <header class="workspace-topbar sticky top-2 z-30 mx-auto grid min-h-[70px] max-w-7xl grid-cols-[1fr_auto] items-center gap-3 rounded-[22px] border border-skino-line bg-white/90 px-3 shadow-skino backdrop-blur-xl md:grid-cols-[1fr_auto_1fr] sm:px-4">
      <button class="workspace-brand flex min-w-0 items-center gap-3 text-left" type="button" @click="openView('home')">
        <img class="size-11 rounded-xl border border-skino-line-orange bg-white object-cover shadow-skino-sm" :src="logo" alt="" />
        <span class="grid leading-tight"><strong class="text-sm font-medium">Skino</strong><small class="mt-0.5 text-[10px] text-skino-muted">ကိုယ်ပိုင် အသားအရေ အလုပ်နေရာ</small></span>
      </button>

      <div class="hidden items-center gap-2 rounded-full border border-skino-line bg-white px-4 py-2 text-[11px] text-skino-muted shadow-skino-sm md:flex"><span class="size-2 rounded-full bg-emerald-500"></span><span>အလုပ်နေရာ</span><b class="font-medium text-skino-ink">/ {{ currentViewTitle }}</b></div>

      <div class="workspace-actions flex items-center gap-2 justify-self-end">
        <button class="workspace-pricing group flex min-h-10 items-center gap-2 rounded-full border border-skino-line-orange bg-white px-3 text-[10px] text-skino-orange-dark shadow-skino-sm transition hover:-translate-y-0.5 hover:border-skino-orange hover:bg-skino-orange-soft" type="button" aria-label="Open pricing plans" @click="pricingOpen = true"><span class="grid size-6 place-items-center rounded-full bg-skino-orange-soft text-[11px] transition group-hover:bg-white">✦</span><span class="hidden sm:inline">Pricing plans</span></button>
        <div class="relative">
        <button class="workspace-profile-trigger flex min-h-11 items-center gap-2 rounded-full border border-skino-line-orange bg-skino-paper p-1.5 pr-3 text-left shadow-skino-sm transition hover:-translate-y-0.5 hover:border-skino-orange" type="button" :aria-expanded="profileOpen" @click="profileOpen = !profileOpen">
          <img v-if="user.avatar_url" class="size-9 rounded-full object-cover" :src="user.avatar_url" alt="" referrerpolicy="no-referrer" />
          <span v-else class="grid size-9 place-items-center rounded-full bg-skino-green text-xs text-white">{{ user.name?.charAt(0) || 'S' }}</span>
          <span class="hidden max-w-32 leading-tight sm:grid"><strong class="truncate text-[11px] font-medium">{{ user.name }}</strong><small class="truncate text-[9px] text-skino-muted">ကိုယ်ရေးအချက်အလက်</small></span><span class="text-xs text-skino-muted">⌄</span>
        </button>
        <div v-if="profileOpen" class="absolute right-0 top-[calc(100%+8px)] z-50 grid w-64 gap-3 rounded-2xl border border-skino-line bg-white p-4 shadow-skino">
          <div class="flex items-center gap-3"><span class="grid size-11 place-items-center rounded-xl bg-skino-green text-sm text-white">{{ user.name?.charAt(0) || 'S' }}</span><span class="grid min-w-0"><strong class="truncate text-sm font-medium">{{ user.name }}</strong><small class="truncate text-[10px] text-skino-muted">{{ user.email }}</small></span></div>
          <div class="grid grid-cols-2 gap-2"><div class="rounded-lg bg-emerald-50 p-2.5"><small class="text-[9px] text-skino-muted">စကင်မှတ်တမ်း</small><strong class="mt-1 block text-sm text-skino-green">{{ history.length }} ခု</strong></div><div class="rounded-lg bg-skino-orange-soft p-2.5"><small class="text-[9px] text-skino-muted">ဒီနေ့ routine</small><strong class="mt-1 block text-sm text-skino-orange-dark">{{ todayProgress }}%</strong></div></div>
          <button class="min-h-10 rounded-lg bg-skino-orange-soft text-[11px] text-skino-orange-dark hover:bg-skino-line-orange" type="button" @click="openProfile">ကိုယ်ရေးအချက်အလက် ပြင်မယ်</button>
          <button class="min-h-10 rounded-lg border border-skino-line text-[11px] text-skino-muted hover:border-red-200 hover:text-red-700" type="button" @click="emit('logout')">အကောင့်မှ ထွက်မယ်</button>
        </div>
        </div>
      </div>
    </header>

    <div v-if="pricingOpen" class="fixed inset-0 z-[70] grid place-items-center bg-[#241710]/35 p-3 backdrop-blur-sm sm:p-6" role="dialog" aria-modal="true" aria-labelledby="dashboard-pricing-title" @click.self="pricingOpen = false">
      <section class="grid max-h-[92svh] w-full max-w-5xl gap-4 overflow-y-auto rounded-[26px] border border-skino-line bg-skino-cream p-4 shadow-[0_30px_90px_rgba(35,20,12,.25)] sm:p-6">
        <header class="flex items-start justify-between gap-4"><div><p class="mb-1 text-[10px] text-skino-orange-dark">Skino plans</p><h2 id="dashboard-pricing-title" class="text-xl font-medium tracking-[-.03em] sm:text-2xl">Choose only when you need more.</h2><p class="mb-0 mt-1 text-[10px] leading-5 text-skino-muted">Your current workspace stays usable. Opening this panel does not change your plan.</p></div><button class="grid size-10 shrink-0 place-items-center rounded-full border border-skino-line bg-white text-lg text-skino-muted hover:border-skino-orange hover:text-skino-orange-dark" type="button" aria-label="Close pricing plans" @click="pricingOpen = false">×</button></header>
        <PricingPlans compact @choose="pricingOpen = false" />
        <p class="mb-0 text-center text-[9px] leading-4 text-skino-muted">Billing is not connected yet. No purchase or subscription will be created from this preview.</p>
      </section>
    </div>

    <div v-if="loading && activeView === 'scan'" class="analysis-loading-overlay" role="dialog" aria-modal="true" aria-labelledby="analysis-loading-title" aria-live="polite">
      <section class="analysis-loading-card">
        <div class="analysis-loading-top"><span><i></i>Skino AI service</span><b>{{ analysisProgress }}%</b></div>
        <div class="analysis-loading-body">
          <div class="analysis-preview"><img v-if="previewUrl" :src="previewUrl" alt="Selected scan preview" /><img v-else :src="cameraMascot" alt="" /><span><i></i><i></i><i></i></span></div>
          <div class="analysis-loading-copy"><img :src="calmMascot" alt="" /><p>သင့်ရလဒ်ကို ပြင်ဆင်နေပါသည်</p><h2 id="analysis-loading-title">{{ currentAnalysisStage.title }}</h2><span>{{ currentAnalysisStage.detail }}</span><div class="analysis-progress-track" :aria-valuenow="analysisProgress" aria-valuemin="0" aria-valuemax="100" role="progressbar"><i :style="{ width: `${analysisProgress}%` }"></i></div><small>Render service နိုးထရန် အချိန်အနည်းငယ်ကြာနိုင်ပါသည်။ ဤစာမျက်နှာကို မပိတ်ပါနှင့်။</small></div>
        </div>
        <div class="analysis-stage-list"><span v-for="(stage, index) in analysisStages" :key="stage.title" :class="{ active: index === analysisStageIndex, complete: index < analysisStageIndex || analysisProgress === 100 }"><i>{{ index < analysisStageIndex || analysisProgress === 100 ? '✓' : index + 1 }}</i><b>{{ stage.title }}</b></span></div>
        <footer><span><i></i>ဓာတ်ပုံကို မပျောက်စေဘဲ ရပ်ပြီး ပြန်စမ်းနိုင်ပါသည်</span><button type="button" @click="cancelAnalysis">စစ်ဆေးမှု ရပ်မယ်</button></footer>
      </section>
    </div>

    <div v-if="loading && activeView !== 'scan'" class="workspace-operation-pill" role="status" aria-live="polite"><i></i><span>{{ operationLabel }}</span></div>

    <section v-if="error || notice" class="mx-auto mt-4 flex min-h-11 max-w-6xl items-center justify-between gap-4 rounded-lg border px-4 py-2.5 text-xs" :class="error ? 'border-red-200 bg-red-50 text-red-700' : 'border-emerald-200 bg-emerald-50 text-skino-green'">
      <span>{{ error || notice }}</span><button class="text-lg leading-none" type="button" @click="error = ''; notice = ''">×</button>
    </section>

    <section v-if="Object.values(loadErrors).some(Boolean)" class="mx-auto mt-3 flex max-w-6xl flex-wrap items-center gap-2 rounded-xl border border-amber-200 bg-amber-50 p-3 text-xs text-amber-900"><span class="mr-auto">အချို့အချက်အလက်များ မတင်နိုင်သေးပါ။ အပိုင်းတစ်ခုချင်း ပြန်စမ်းနိုင်သည်။</span><button v-if="loadErrors.history" class="rounded-lg border border-amber-300 bg-white px-3 py-2" type="button" :disabled="Boolean(retryingSection)" @click="retryWorkspaceSection('history')">{{ retryingSection === 'history' ? 'တင်နေသည်…' : 'မှတ်တမ်း ပြန်တင်မယ်' }}</button><button v-if="loadErrors.routine" class="rounded-lg border border-amber-300 bg-white px-3 py-2" type="button" :disabled="Boolean(retryingSection)" @click="retryWorkspaceSection('routine')">{{ retryingSection === 'routine' ? 'တင်နေသည်…' : 'Routine ပြန်တင်မယ်' }}</button><button v-if="loadErrors.profile" class="rounded-lg border border-amber-300 bg-white px-3 py-2" type="button" :disabled="Boolean(retryingSection)" @click="retryWorkspaceSection('profile')">{{ retryingSection === 'profile' ? 'တင်နေသည်…' : 'Profile ပြန်တင်မယ်' }}</button></section>

    <section v-if="pageLoading" class="workspace-loading-screen" role="status" aria-live="polite">
      <div class="workspace-loading-brand"><span><img :src="calmMascot" alt="" /><i></i></span><div><p>Skino Workspace</p><h1>သင့်အသားအရေ အချက်အလက်များကို ပြင်ဆင်နေသည်</h1><small>Loading scan history, routine and private profile…</small></div></div>
      <div class="workspace-loading-bar"><i></i></div>
      <div class="workspace-skeleton-grid" aria-hidden="true"><span v-for="index in 5" :key="index"><i></i><b></b><small></small><em></em></span></div>
    </section>

    <section v-else-if="activeView === 'home'" class="workspace-view mx-auto grid max-w-7xl content-start py-5 sm:py-8 lg:py-10">
      <div class="workspace-module-grid grid place-content-center gap-3 sm:gap-4">
        <button v-for="module in workspaceModules" :key="module.key" class="workspace-module-card group grid w-full content-start justify-items-center gap-2 rounded-2xl border border-skino-line bg-white p-4 text-center shadow-skino-sm transition hover:-translate-y-1 hover:border-skino-line-orange hover:shadow-skino sm:gap-3 sm:p-5" type="button" :style="{ '--module-accent': module.accent }" @click="openModule(module)">
          <span class="grid size-20 place-items-center overflow-hidden rounded-2xl bg-skino-paper p-2 transition group-hover:bg-skino-orange-soft sm:size-24"><img class="size-full object-contain" :src="module.icon" alt="" /></span>
          <strong class="text-sm font-medium sm:text-base">{{ module.title }}</strong>
          <small class="min-h-8 text-[12px] leading-5 text-skino-muted">{{ module.subtitle }}</small>
          <span class="mt-auto rounded-full px-3 py-1.5 text-[11px] font-medium" :style="{ color: module.accent, backgroundColor: `${module.accent}12` }">{{ module.meta }}</span>
        </button>
      </div>
    </section>

    <section v-else-if="activeView === 'profile'" class="workspace-view mx-auto mt-4 grid max-w-5xl gap-4 sm:mt-6">
      <div class="flex items-center gap-3 border-b border-skino-line pb-4">
        <button class="min-h-10 rounded-xl border border-skino-line bg-white px-3 text-[11px] text-skino-muted hover:border-skino-orange" type="button" @click="openView('home')">‹ ပင်မ</button>
        <span class="grid size-11 place-items-center rounded-xl bg-emerald-50 text-sm text-skino-green">{{ user.name?.charAt(0) || 'S' }}</span>
        <div><p class="mb-0 text-[10px] text-skino-orange-dark">ကိုယ်ရေးအချက်အလက်နှင့် privacy</p><h1 class="text-xl font-medium sm:text-2xl">သင့် Skin Profile</h1></div>
      </div>

      <div class="grid gap-4 lg:grid-cols-[minmax(0,1.35fr)_minmax(280px,.65fr)]">
        <form class="grid gap-5 rounded-2xl border border-skino-line bg-white p-4 shadow-skino-sm sm:p-6" @submit.prevent="saveProfile">
          <div class="flex items-center gap-3 rounded-2xl bg-skino-paper p-3"><img v-if="user.avatar_url" class="size-14 rounded-2xl object-cover" :src="user.avatar_url" alt="" referrerpolicy="no-referrer" /><span v-else class="grid size-14 place-items-center rounded-2xl bg-skino-green text-lg text-white">{{ user.name?.charAt(0) || 'S' }}</span><span class="grid min-w-0 gap-1"><span class="truncate text-sm font-medium">{{ user.email }}</span><small class="text-[10px] leading-4 text-skino-muted">Email ကို login အကောင့်မှ ထိန်းချုပ်ထားပါသည်</small></span></div>

          <label class="grid gap-2 text-xs"><span class="font-medium">အမည်</span><input v-model="profileForm.name" class="min-h-11 rounded-xl border border-skino-line px-3 text-xs outline-none focus:border-skino-orange" maxlength="100" required /></label>

          <label class="grid gap-2 text-xs"><span class="font-medium">အသက်အုပ်စု <small class="ml-1 font-normal text-skino-muted">ရွေးချယ်နိုင်သည်</small></span><select v-model="profileForm.age_band" class="min-h-11 rounded-xl border border-skino-line bg-white px-3 text-xs outline-none focus:border-skino-orange"><option v-for="option in ageBandOptions" :key="option.value" :value="option.value">{{ option.label }}</option></select><small class="text-[9px] leading-4 text-skino-muted">မွေးသက္ကရာဇ်အတိအကျ မသိမ်းပါ။ သင်ခွင့်ပြုထားမှသာ dataset coverage စစ်ဆေးရန် အသုံးပြုပါမည်။</small></label>

          <fieldset class="grid gap-2"><legend class="text-xs font-medium">မိမိရွေးချယ်သော skin tone reference <small class="ml-1 font-normal text-skino-muted">ရွေးချယ်နိုင်သည်</small></legend><div class="flex flex-wrap gap-2"><button v-for="(tone, index) in skinToneOptions" :key="tone" class="grid size-10 place-items-center rounded-full border-2 text-[9px] transition" :class="profileForm.skin_tone_scale === index + 1 ? 'scale-110 border-skino-orange shadow-skino-sm' : 'border-white ring-1 ring-skino-line'" :style="{ backgroundColor: tone, color: index > 4 ? 'white' : '#30231d' }" type="button" :aria-label="`Skin tone ${index + 1}`" @click="profileForm.skin_tone_scale = profileForm.skin_tone_scale === index + 1 ? null : index + 1">{{ index + 1 }}</button></div><small class="text-[9px] leading-4 text-skino-muted">AI က အလိုအလျောက် လူမျိုး သို့မဟုတ် skin tone မခန့်မှန်းပါ။ ဤရွေးချယ်မှုသည် ကိုယ်တိုင်ဖော်ပြသော reference သာဖြစ်သည်။</small></fieldset>

          <fieldset class="grid gap-2"><legend class="text-xs font-medium">အဓိက skin goals <small class="ml-1 font-normal text-skino-muted">၅ ခုအထိ</small></legend><div class="flex flex-wrap gap-2"><button v-for="goal in skinGoalOptions" :key="goal.value" class="min-h-9 rounded-full border px-3 text-[10px] transition" :class="profileForm.skin_goals.includes(goal.value) ? 'border-skino-orange bg-skino-orange-soft text-skino-orange-dark' : 'border-skino-line bg-white text-skino-muted hover:border-skino-line-orange'" type="button" @click="toggleSkinGoal(goal.value)">{{ profileForm.skin_goals.includes(goal.value) ? '✓ ' : '' }}{{ goal.label }}</button></div></fieldset>

          <button class="inline-flex min-h-11 items-center justify-center gap-2 rounded-xl bg-skino-orange px-5 text-xs font-medium text-white hover:bg-skino-orange-dark disabled:opacity-40 sm:justify-self-start" type="submit" :disabled="profileSaving || !profileForm.name.trim()"><i v-if="profileSaving" class="button-spinner light"></i>{{ profileSaving ? 'သိမ်းနေသည်…' : 'Profile သိမ်းမယ်' }}</button>
        </form>

        <aside class="grid content-start gap-4">
          <article class="grid gap-3 rounded-2xl border border-skino-line bg-white p-4 shadow-skino-sm sm:p-5"><div><p class="mb-1 text-[10px] text-skino-orange-dark">AI training consent</p><h2 class="text-base font-medium">သင်ဆုံးဖြတ်နိုင်ပါသည်</h2></div><p class="mb-0 text-[10px] leading-5 text-skino-muted">ပုံမှန် scan result ရရန် training consent မလိုပါ။ ဖွင့်ထားပါက consent ရှိသော scan ကို review queue သို့သာ ပို့ပြီး dermatologist review မပြီးမချင်း production model တွင် မသုံးသင့်ပါ။</p><label class="flex cursor-pointer items-center justify-between gap-4 rounded-xl bg-skino-paper p-3"><span class="grid gap-1"><span class="text-xs font-medium">AI တိုးတက်ရေးတွင် ပါဝင်မယ်</span><small class="text-[9px] text-skino-muted">နောက်မှ အချိန်မရွေး ပိတ်နိုင်သည်</small></span><input v-model="localTrainingConsent" class="size-5 accent-skino-green" type="checkbox" @change="saveTrainingChoice" /></label></article>

          <article class="grid gap-3 rounded-2xl border border-emerald-200 bg-emerald-50 p-4"><h2 class="text-sm font-medium text-skino-green">Responsible AI readiness</h2><div v-for="item in [['✓','Consent before collection'],['✓','Age band and tone are optional'],['✓','Device and image quality logged'],['→','Dermatologist review required'],['→','Subject-separated validation required']]" :key="item[1]" class="grid grid-cols-[22px_1fr] gap-2 text-[10px] text-skino-muted"><span class="grid size-5 place-items-center rounded-full bg-white text-skino-green">{{ item[0] }}</span><span>{{ item[1] }}</span></div></article>
        </aside>
      </div>
    </section>

    <section v-else-if="activeView === 'safety'" class="workspace-view mx-auto mt-4 grid max-w-5xl gap-4 sm:mt-6">
      <div class="flex items-center gap-3 border-b border-skino-line pb-4"><button class="min-h-10 rounded-xl border border-skino-line bg-white px-3 text-[11px] text-skino-muted hover:border-skino-orange" type="button" @click="openView('home')">‹ ပင်မ</button><span class="grid size-11 place-items-center rounded-xl bg-emerald-50"><img class="size-10 object-contain" :src="calmMascot" alt="" /></span><div><p class="mb-0 text-[10px] text-skino-green">Help, safety and privacy</p><h1 class="text-xl font-medium sm:text-2xl">သင့်ဒေတာ၊ သင့်ဆုံးဖြတ်ချက်</h1></div></div>

      <div class="grid gap-4 lg:grid-cols-[1.1fr_.9fr]">
        <article class="grid content-start gap-4 rounded-2xl border border-skino-line bg-white p-4 shadow-skino-sm sm:p-6"><div><p class="mb-1 text-[10px] text-skino-orange-dark">Skino ကို နားလည်ရန်</p><h2 class="text-lg font-medium">Wellness guidance ဖြစ်ပြီး diagnosis မဟုတ်ပါ</h2><p class="mb-0 mt-2 text-[11px] leading-5 text-skino-muted">Skino သည် ပုံအရည်အသွေး၊ မြင်ရသော skin signals နှင့် မျက်နှာနေရာခွဲများကို အသုံးပြုပြီး နေ့စဉ် care guidance ပေးပါသည်။ ဆရာဝန်၏ ရောဂါရှာဖွေမှုကို အစားမထိုးပါ။</p></div><div class="grid gap-2 sm:grid-cols-2"><div v-for="item in [['ကင်မရာလမ်းညွှန်','Face alignment နှင့် quality check ကို browser အတွင်းလုပ်သည်။'],['စကင်ရလဒ်','မြင်ရသောအချက်များကို wellness guidance အဖြစ်သာ ပြသည်။'],['သိမ်းဆည်းမှု','Login ဝင်ထားသော scan များကို History မှ ပြန်ကြည့်/ဖျက်နိုင်သည်။'],['ကျွမ်းကျင်သူ','နာကျင်ခြင်း သို့မဟုတ် လျင်မြန်စွာပြောင်းလဲလျှင် specialist ကို ဆက်သွယ်ပါ။']]" :key="item[0]" class="rounded-xl bg-skino-paper p-3"><strong class="text-[11px] font-medium">{{ item[0] }}</strong><p class="mb-0 mt-1 text-[9px] leading-4 text-skino-muted">{{ item[1] }}</p></div></div></article>

        <div class="grid content-start gap-4">
          <article class="grid gap-3 rounded-2xl border border-emerald-200 bg-emerald-50 p-4 sm:p-5"><div><p class="mb-1 text-[10px] text-skino-green">Model-learning consent</p><h2 class="text-base font-medium">AI တိုးတက်ရေးတွင် ပါဝင်မလား?</h2></div><p class="mb-0 text-[10px] leading-5 text-skino-muted">ပိတ်ထားပါက နောက်ထပ် scan များကို model-improvement review queue သို့ မပို့ပါ။ ပုံမှန် scan နှင့် routine ကို ဆက်သုံးနိုင်ပါသည်။</p><label class="flex cursor-pointer items-center justify-between gap-4 rounded-xl border border-white bg-white p-3"><span class="grid gap-1"><strong class="text-xs font-medium">Model learning ခွင့်ပြုမယ်</strong><small class="text-[9px] text-skino-muted">ရွေးချယ်နိုင်ပြီး အချိန်မရွေး ပိတ်နိုင်သည်</small></span><input v-model="localTrainingConsent" class="size-5 accent-skino-green" type="checkbox" @change="saveTrainingChoice" /></label><span class="text-[9px] leading-4" :class="localTrainingConsent ? 'text-skino-green' : 'text-skino-muted'">{{ localTrainingConsent ? 'ဖွင့်ထားသည် — consent ရှိသော scan များကို review ပြီးမှသာ သင်ကြားရေးအတွက် စဉ်းစားပါမည်။' : 'ပိတ်ထားသည် — scan အသစ်များကို model learning အတွက် မတင်ပါ။' }}</span></article>

          <article class="grid gap-3 rounded-2xl border border-skino-line bg-white p-4 shadow-skino-sm"><h2 class="text-sm font-medium">သင့် privacy controls</h2><button class="min-h-10 rounded-xl border border-skino-line bg-skino-paper px-3 text-left text-[10px] hover:border-skino-orange" type="button" @click="openView('profile')">Profile နှင့် optional demographic data ကို ပြင်မယ် →</button><button class="min-h-10 rounded-xl border border-skino-line bg-skino-paper px-3 text-left text-[10px] hover:border-skino-orange" type="button" @click="openView('history')">သိမ်းထားသော scan ကို ကြည့်/ဖျက်မယ် →</button></article>
          <article class="rounded-2xl border border-amber-200 bg-amber-50 p-4"><strong class="text-xs font-medium text-amber-900">အရေးပေါ်အခြေအနေ</strong><p class="mb-0 mt-1 text-[10px] leading-5 text-skino-muted">အသက်ရှူခက်ခြင်း၊ အလွန်နာကျင်ခြင်း သို့မဟုတ် လျင်မြန်စွာပြန့်လာသောအခြေအနေတွင် Skino ကို မစောင့်ဘဲ အရေးပေါ်ဆေးကုသမှု ရယူပါ။</p></article>
        </div>
      </div>
    </section>

    <section v-else-if="activeView === 'scan'" class="workspace-view mx-auto mt-3 grid max-w-5xl gap-3 sm:mt-4 lg:h-[calc(100svh-100px)] lg:grid-rows-[auto_minmax(0,1fr)] lg:overflow-hidden">
      <div class="flex items-center gap-3 border-b border-skino-line pb-3">
        <button class="min-h-10 rounded-xl border border-skino-line bg-white px-3 text-[11px] text-skino-muted hover:border-skino-orange" type="button" @click="openView('home')">‹ ပင်မ</button>
        <span class="grid size-11 place-items-center rounded-xl bg-skino-orange-soft"><img class="size-9 object-contain" :src="scanIcon" alt="" /></span>
        <div><p class="mb-0 text-[10px] text-skino-orange-dark">မျက်နှာ စကင်</p><h1 class="text-xl font-medium sm:text-2xl">မျက်နှာကို တည့်တည့်ထားပြီး စကင်လုပ်ပါ</h1></div>
      </div>

      <div class="grid min-h-0 gap-3 lg:grid-cols-[minmax(0,1fr)_260px]">
        <div class="grid min-h-0 grid-rows-[minmax(0,1fr)_auto] rounded-2xl border border-skino-line bg-white p-3 shadow-skino-sm sm:p-4">
          <div class="relative mx-auto grid h-[min(54svh,460px)] min-h-[290px] w-full place-items-center overflow-hidden rounded-2xl bg-[#111816] lg:h-auto lg:min-h-0">
            <video v-show="cameraActive" ref="video" class="absolute inset-0 size-full object-cover [transform:scaleX(-1)]" playsinline muted></video>
            <img v-if="previewUrl && !cameraActive" class="absolute inset-0 size-full bg-[#111816] object-contain" :src="previewUrl" alt="ရိုက်ထားသော မျက်နှာပုံ" />
            <div v-if="!cameraActive && !previewUrl" class="grid place-items-center gap-3 px-8 text-center text-white"><img class="size-24 object-contain" :src="cameraMascot" alt="" /><strong class="text-base font-medium">စကင်လုပ်ရန် အဆင်သင့်ပါပြီ</strong><small class="max-w-sm text-[11px] leading-5 text-white/65">အလင်းရောင်ညီသော နေရာတွင် ဆံပင်ကို နဖူးမဖုံးအောင်ထားပြီး ကင်မရာကို တည့်တည့်ကြည့်ပါ။</small><button class="mt-1 min-h-11 rounded-xl bg-skino-orange px-6 text-xs font-medium text-white shadow-lg" type="button" @click="startCamera">ကင်မရာ ဖွင့်မယ်</button></div>

            <div class="scan-face-guide pointer-events-none absolute inset-[9%_11%_13%] sm:inset-[9%_18%_13%]" :class="{ 'opacity-25': !cameraActive && !previewUrl, 'scan-guide-good': faceGuide.state === 'good' }">
              <span class="absolute left-0 top-0 size-16 rounded-tl-[42px] border-l-[3px] border-t-[3px]" :class="faceGuide.state === 'good' ? 'border-emerald-300' : 'border-white/80'"></span>
              <span class="absolute right-0 top-0 size-16 rounded-tr-[42px] border-r-[3px] border-t-[3px]" :class="faceGuide.state === 'good' ? 'border-emerald-300' : 'border-white/80'"></span>
              <span class="absolute bottom-0 left-0 size-16 rounded-bl-[42px] border-b-[3px] border-l-[3px]" :class="faceGuide.state === 'good' ? 'border-emerald-300' : 'border-white/80'"></span>
              <span class="absolute bottom-0 right-0 size-16 rounded-br-[42px] border-b-[3px] border-r-[3px]" :class="faceGuide.state === 'good' ? 'border-emerald-300' : 'border-white/80'"></span>
              <span class="absolute left-1/2 top-1/2 h-0.5 w-16 -translate-x-1/2 rounded-full" :class="faceGuide.state === 'good' ? 'bg-emerald-300' : 'bg-white/70'"></span>
            </div>

            <svg v-if="developerOverlay && previewUrl && zoneOverlayPolygons.length" class="pointer-events-none absolute inset-0 size-full" viewBox="0 0 100 100" preserveAspectRatio="none" aria-label="Developer zone mask overlay">
              <g v-for="zone in zoneOverlayPolygons" :key="zone.key"><polygon :points="zone.points" :fill="`${zone.color}38`" :stroke="zone.color" stroke-width="0.7" vector-effect="non-scaling-stroke" /><text :x="zone.x" :y="zone.y" fill="white" font-size="2.4" font-weight="700" text-anchor="middle" paint-order="stroke" stroke="#111" stroke-width="0.45">{{ zone.key }}{{ zone.signal ? ` ${zone.signal.score}` : '' }}</text></g>
            </svg>

            <div v-if="cameraActive || previewUrl" class="absolute inset-x-3 bottom-[68px] flex items-center gap-2 rounded-xl border px-3 py-2 text-[10px] backdrop-blur-md" :class="faceGuide.state === 'good' ? 'border-emerald-400/40 bg-emerald-950/75 text-emerald-100' : faceGuide.state === 'loading' ? 'border-white/20 bg-black/65 text-white' : 'border-amber-300/40 bg-black/70 text-amber-100'"><span class="size-2 shrink-0 rounded-full" :class="faceGuide.state === 'good' ? 'bg-emerald-400' : faceGuide.state === 'loading' ? 'animate-pulse bg-white' : 'bg-amber-300'"></span><span class="flex-1">{{ faceGuide.message }}</span><b v-if="faceGuide.confidence" class="font-medium">{{ faceGuide.confidence }}%</b></div>
            <div class="absolute left-3 top-3 flex items-center gap-1.5 rounded-full border border-white/15 bg-black/55 px-2.5 py-1.5 text-[9px] text-white/80 backdrop-blur-md"><span class="size-1.5 rounded-full bg-emerald-400"></span>Browser-only guidance</div>
            <div v-if="cameraActive" class="absolute right-3 top-3 flex items-center gap-1.5 rounded-full border border-white/20 bg-black/65 px-2.5 py-1.5 text-[9px] text-white backdrop-blur-md"><span class="mr-1">{{ capturingFrames ? 'ရိုက်နေသည်' : '3-frame' }}</span><i v-for="step in 3" :key="step" class="size-2 rounded-full transition" :class="captureProgress >= step ? 'bg-emerald-400 shadow-[0_0_0_3px_rgba(52,211,153,.16)]' : 'bg-white/30'"></i></div>
            <button v-if="cameraActive" class="absolute inset-x-3 bottom-3 z-10 min-h-12 rounded-xl bg-skino-orange px-5 text-xs font-medium text-white shadow-[0_12px_30px_rgba(0,0,0,.35)] disabled:opacity-50" type="button" :disabled="!canCapture || capturingFrames" @click="captureFrame">{{ capturingFrames ? `ပုံရိုက်နေသည် ${captureProgress}/3` : canCapture ? 'ပုံ ၃ ပုံရိုက်ပြီး AI နှိုင်းယှဉ်မယ်' : 'မျက်နှာအနေအထားကို အရင်ပြင်ပါ' }}</button>
            <button v-else-if="previewUrl && !loading" class="absolute inset-x-3 bottom-3 z-10 min-h-12 rounded-xl bg-skino-orange px-5 text-xs font-medium text-white shadow-[0_12px_30px_rgba(0,0,0,.35)] disabled:opacity-50" type="button" :disabled="!canAnalyze || !online" @click="submitScan">{{ canAnalyze ? 'အသားအရေ ရလဒ်ကြည့်မယ် →' : 'မှန်ကန်သော ဓာတ်ပုံ လိုအပ်သည်' }}</button>
            <canvas ref="canvas" hidden></canvas>
          </div>

          <div class="grid gap-2 pt-2 sm:grid-cols-2">
            <button v-if="previewUrl" class="min-h-10 rounded-xl border border-skino-line bg-white px-5 text-xs hover:border-skino-orange hover:text-skino-orange-dark" type="button" @click="retake">ပြန်ရိုက်မယ်</button>
            <label class="grid min-h-10 cursor-pointer place-items-center rounded-xl border border-skino-line bg-white px-5 text-xs hover:border-skino-orange hover:text-skino-orange-dark">ဓာတ်ပုံ ရွေးမယ်<input class="sr-only" type="file" accept="image/jpeg,image/png,image/webp" capture="user" @change="chooseFile" /></label>
          </div>
        </div>

        <aside class="grid min-h-0 content-start gap-2.5 rounded-2xl border border-skino-line bg-white p-4 shadow-skino-sm lg:overflow-y-auto">
          <div><p class="mb-1 text-[10px] text-skino-orange-dark">စကင် လမ်းညွှန်</p><h2 class="text-base font-medium">ပုံကြည်လင်စေရန် စစ်ဆေးပါ</h2></div>
          <div v-for="item in [['၁','မျက်နှာတစ်ခုတည်း','ညှိကွက်အတွင်း လူတစ်ယောက်တည်းထားပါ။'],['၂','အလယ်တွင် တည့်တည့်','မျက်နှာတစ်ခုလုံး မြင်ရပြီး ခေါင်းမစောင်းပါစေနှင့်။'],['၃','အလင်းရောင်ညီညာ','အရိပ်ပြင်းခြင်းနှင့် filter များကို ရှောင်ပါ။']]" :key="item[0]" class="grid grid-cols-[30px_1fr] gap-2 rounded-xl bg-skino-paper p-2.5"><span class="grid size-7 place-items-center rounded-full bg-white text-[10px] text-skino-orange">{{ item[0] }}</span><span class="grid gap-0.5"><strong class="text-[11px] font-medium">{{ item[1] }}</strong><small class="text-[9px] leading-4 text-skino-muted">{{ item[2] }}</small></span></div>
          <div class="grid gap-1 rounded-xl border border-violet-200 bg-violet-50 p-3"><strong class="text-[12px] font-medium text-violet-800">Three-frame median analysis</strong><small class="text-[11px] leading-5 text-skino-muted">ပုံ ၃ ပုံလုံးကို AI ဖြင့် စစ်ပြီး zone နှင့် signal တစ်ခုချင်း၏ အလယ်တန်ဖိုးကို အသုံးပြုပါမည်။ ကင်မရာကွာခြားမှုနှင့် frame တစ်ခုတည်း၏ noise ကို လျှော့ချပေးသည်။</small></div>
          <label class="flex cursor-pointer items-center justify-between gap-3 rounded-xl border border-sky-200 bg-sky-50 p-3"><span class="grid gap-0.5"><strong class="text-[11px] font-medium text-sky-900">Developer zone overlay</strong><small class="text-[9px] leading-4 text-skino-muted">Mask နေရာနှင့် zone score ကို ပုံပေါ်တွင်ပြမည်</small></span><input v-model="developerOverlay" class="size-4 accent-sky-600" type="checkbox" /></label>
          <div class="grid gap-1 rounded-xl border border-emerald-200 bg-emerald-50 p-3"><strong class="text-[11px] font-medium">သင့်အချက်အလက်ကို ကာကွယ်ထားသည်</strong><small class="text-[10px] leading-4 text-skino-muted">ကင်မရာလမ်းညွှန်ကို ဝဘ်ဘရောက်ဇာအတွင်းတွင်သာ လုပ်ဆောင်သည်။</small></div>
          <button v-if="loading" class="mt-1 min-h-11 w-full rounded-xl border border-red-200 bg-white px-4 text-xs font-medium text-red-700" type="button" @click="cancelAnalysis">စစ်ဆေးမှု ရပ်မယ်</button><button v-else class="mt-1 hidden min-h-12 w-full rounded-xl bg-skino-orange px-4 text-xs font-medium text-white shadow-skino-sm hover:bg-skino-orange-dark disabled:cursor-not-allowed disabled:opacity-40 lg:block" type="button" :disabled="!canAnalyze || !online" @click="submitScan">{{ !online ? 'အင်တာနက်ချိတ်ဆက်ပြီး ပြန်စမ်းပါ' : scanFailure && canAnalyze ? 'ဓာတ်ပုံမပျောက်ဘဲ ပြန်စမ်းမယ် →' : canAnalyze ? 'အသားအရေ ရလဒ်ကြည့်မယ် →' : 'မှန်ကန်သော ဓာတ်ပုံ အရင်ရိုက်ပါ' }}</button>
        </aside>
      </div>
    </section>

    <section v-else-if="activeView === 'result' && latestResult" class="workspace-view mx-auto mt-4 grid max-w-5xl gap-3 text-[#30231d] sm:mt-5 sm:gap-4">
      <div class="flex flex-wrap items-center gap-3 border-b border-skino-line pb-4">
        <button class="min-h-10 rounded-xl border border-skino-line bg-white px-3 text-[11px] text-skino-muted hover:border-skino-orange" type="button" @click="openView('home')">‹ ပင်မ</button>
        <span class="grid size-11 place-items-center rounded-xl bg-skino-orange-soft"><img class="size-9 object-contain" :src="progressIcon" alt="" /></span>
        <div class="mr-auto"><p class="mb-0 text-[10px] text-skino-orange-dark">{{ formatDate(latestResult.created_at) }}</p><h1 class="text-xl font-medium sm:text-2xl">စကင် ရလဒ်</h1></div>
        <button class="min-h-10 rounded-xl border border-skino-line bg-white px-3 text-[11px] hover:border-skino-orange" type="button" @click="openView('scan')">စကင်အသစ် လုပ်မယ်</button>
      </div>

      <div v-if="latestResult.scan_quality?.level !== 'good'" class="grid gap-2 rounded-2xl border border-amber-200 bg-amber-50 p-4 sm:grid-cols-[1fr_auto] sm:items-center"><div><strong class="text-xs font-medium">ပုံအရည်အသွေးကို ပြန်စစ်ရန်လိုသည်</strong><p class="mb-0 mt-1 text-[11px] leading-5 text-skino-muted">အလင်းရောင်နှင့် မျက်နှာအနေအထားက ရလဒ်အပေါ် သက်ရောက်နိုင်ပါသည်။</p></div><button class="min-h-10 justify-self-start rounded-xl border border-amber-300 bg-white px-3 text-[11px] text-skino-orange-dark" type="button" @click="openView('scan')">ပြန်စကင်မယ်</button></div>

      <article class="grid gap-3 overflow-hidden rounded-3xl border border-skino-line-orange bg-[#fffaf5] p-3 shadow-skino sm:grid-cols-[180px_1fr] sm:p-4">
        <div class="grid min-h-40 place-items-center content-center rounded-2xl bg-[linear-gradient(145deg,#f36a16,#d9540a)] text-white shadow-[0_16px_34px_rgba(217,84,10,.2)]"><div class="grid size-28 place-items-center content-center rounded-full border-[8px] border-white/25 bg-white/10"><strong class="text-4xl font-medium text-white">{{ latestResult.skin_health_score }}</strong><small class="mt-1 text-[10px] text-white/85">အသားအရေ အမှတ်</small></div></div>
        <div class="grid content-center gap-3 rounded-2xl bg-white p-3 sm:p-4"><div><small class="text-[10px] text-[#786c64]">အသားအရေ အမျိုးအစား</small><h2 class="mt-1 text-xl font-medium text-[#30231d]">{{ skinTypeMy(latestResult.skin_type) }}</h2><p class="mb-0 mt-1 text-[11px] text-[#786c64]">ရလဒ်ယုံကြည်မှု {{ Math.round((latestResult.skin_type_confidence || 0) * 100) }}% · ပုံအရည်အသွေးအပေါ် မူတည်ပါသည်</p></div><div class="grid grid-cols-3 gap-2"><div class="rounded-xl bg-[#eaf7f1] p-3 text-[#165c4b]"><small class="text-[9px] text-[#397667]">ဝက်ခြံ</small><strong class="mt-1 block text-xs font-medium sm:text-sm">{{ severityMy(latestResult.acne_severity) }}</strong></div><div class="rounded-xl bg-[#f3efff] p-3 text-[#604a9b]"><small class="text-[9px] text-[#7867a4]">တွေ့ရှိချက်</small><strong class="mt-1 block text-xs font-medium sm:text-sm">{{ latestResult.concerns?.length || 0 }} ခု</strong></div><div class="rounded-xl bg-[#fff3df] p-3 text-[#8a5a16]"><small class="text-[9px] text-[#98733b]">ပုံအရည်အသွေး</small><strong class="mt-1 block text-xs font-medium sm:text-sm">{{ latestResult.scan_quality?.level === 'good' ? 'ကောင်း' : latestResult.scan_quality?.level === 'medium' ? 'အသင့်အတင့်' : 'နိမ့်' }}</strong></div></div></div>
      </article>

      <article class="rounded-2xl border border-skino-line bg-white p-4 text-[#30231d] shadow-skino-sm sm:p-5">
        <div class="mb-4"><p class="mb-1 text-[10px] text-skino-orange-dark">မြင်နိုင်သော အသားအရေ အချက်များ</p><h2 class="text-base font-medium">Skino တွေ့ရှိထားသော အခြေအနေ</h2></div>
        <div v-if="latestResult.concerns?.length" class="grid gap-2 sm:grid-cols-2 lg:grid-cols-3"><div v-for="concern in latestResult.concerns" :key="concern.name" class="grid min-h-24 grid-cols-[1fr_auto] content-center gap-2 rounded-2xl border border-black/5 p-3.5" :style="{ backgroundColor: concernPalette(concern.name).background, color: concernPalette(concern.name).color }"><span class="grid gap-1"><strong class="text-xs font-medium">{{ concernMy(concern.name) }}</strong><small class="text-[9px] opacity-75">{{ severityMy(concern.severity) }}</small></span><b class="rounded-full bg-white/75 px-2 py-1 text-xs font-medium">{{ Math.round((concern.confidence || 0) * 100) }}%</b><span class="col-span-2 h-1.5 overflow-hidden rounded-full bg-white/80"><i class="block h-full rounded-full" :style="{ width: metricPercent(concern.confidence), backgroundColor: concernPalette(concern.name).bar }"></i></span></div></div>
        <div v-else class="rounded-xl bg-emerald-50 p-4 text-xs leading-5 text-skino-green">ထင်ရှားသော အသားအရေပြဿနာ မတွေ့ရှိပါ။ အသေးစိတ်ကို မျက်နှာ အသားအရေမြေပုံတွင် ကြည့်နိုင်သည်။</div>
      </article>

      <article class="overflow-hidden rounded-2xl border border-skino-line bg-white text-[#30231d] shadow-skino-sm">
        <button class="flex w-full items-center gap-3 p-4 text-left sm:p-5" type="button" :aria-expanded="skinMapOpen" @click="skinMapOpen = !skinMapOpen"><span class="grid size-11 place-items-center rounded-xl bg-emerald-50"><img class="size-9 object-contain" :src="progressIcon" alt="" /></span><span class="grid flex-1 gap-1"><strong class="text-base font-medium">မျက်နှာ အသားအရေမြေပုံ</strong><small class="text-[10px] leading-4 text-skino-muted">မျက်နှာ၏ ဘယ်နေရာတွင် ဘာအချက် ပိုမြင်ရသည်ကို ကြည့်ပါ</small></span><span class="grid size-9 place-items-center rounded-full bg-skino-paper text-lg text-skino-orange transition" :class="{ 'rotate-180': skinMapOpen }">⌄</span></button>
        <Transition name="skin-map"><div v-if="skinMapOpen" class="skin-map-panel grid gap-2 border-t border-skino-line p-4 sm:p-5">
          <div v-if="developerOverlay && previewUrl && zoneOverlayPolygons.length" class="relative mx-auto mb-2 aspect-square w-full max-w-md overflow-hidden rounded-2xl bg-[#111816]"><img class="absolute inset-0 size-full object-contain" :src="previewUrl" alt="Zone developer preview" /><svg class="pointer-events-none absolute inset-0 size-full" viewBox="0 0 100 100" preserveAspectRatio="none"><g v-for="zone in zoneOverlayPolygons" :key="zone.key"><polygon :points="zone.points" :fill="`${zone.color}38`" :stroke="zone.color" stroke-width="0.7" vector-effect="non-scaling-stroke" /><text :x="zone.x" :y="zone.y" fill="white" font-size="2.4" font-weight="700" text-anchor="middle" paint-order="stroke" stroke="#111" stroke-width="0.45">{{ zone.key }}{{ zone.signal ? ` · ${zone.signal.score}` : '' }}</text></g></svg></div>
          <template v-if="latestResult.skin_zones?.length">
            <div v-for="zone in latestResult.skin_zones" :key="zone.key" class="overflow-hidden rounded-xl border border-skino-line bg-skino-paper">
              <button class="flex w-full items-center gap-3 p-3 text-left" type="button" @click="activeZoneKey = activeZoneKey === zone.key ? '' : zone.key"><span class="grid size-10 place-items-center rounded-xl bg-white text-xs font-medium" :class="zone.score >= 70 ? 'text-skino-green' : 'text-skino-orange-dark'">{{ zone.score }}</span><span class="grid flex-1 gap-1"><strong class="text-xs font-medium">{{ zoneNameMy(zone) }}</strong><small class="text-[9px] text-skino-muted">{{ zone.concerns?.length ? zone.concerns.map((item) => concernMy(item.name)).join('၊ ') : 'ထင်ရှားသော အချက် မရှိပါ' }}</small></span><span class="text-xs text-skino-muted">{{ activeZoneKey === zone.key ? 'ပိတ်မယ်' : 'အသေးစိတ်' }}</span></button>
              <div v-if="activeZoneKey === zone.key" class="grid gap-2 border-t border-skino-line bg-white p-3"><div v-for="metric in [['အဆီပြန်မှု',zone.oiliness,'#f36a16'],['အမည်းစက်',zone.dark_spots,'#8e6deb'],['နီမြန်းမှု',zone.redness,'#e95d48'],['မညီညာမှု',zone.texture,'#0e5c56'],['ခြောက်သွေ့မှု',zone.dryness,'#7a8f72']]" :key="metric[0]" class="grid grid-cols-[74px_1fr_34px] items-center gap-2 text-[9px] text-skino-muted"><span>{{ metric[0] }}</span><span class="h-1.5 overflow-hidden rounded-full bg-skino-line"><i class="block h-full rounded-full" :style="{ width: metricPercent(metric[1]), backgroundColor: metric[2] }"></i></span><b class="text-right font-medium">{{ metricPercent(metric[1]) }}</b></div></div>
            </div>
          </template>
          <div v-else class="rounded-xl border border-dashed border-skino-line p-5 text-center text-xs leading-5 text-skino-muted">ဤစကင်အဟောင်းတွင် နေရာခွဲ အသေးစိတ် မရှိပါ။ အသားအရေမြေပုံအသစ်ရရန် ပြန်စကင်ပါ။</div>
        </div></Transition>
      </article>

      <article class="rounded-2xl border border-skino-line bg-white p-4 shadow-skino-sm sm:p-5"><div class="flex items-center gap-3"><img class="size-12 object-contain" :src="routineIcon" alt="" /><div><p class="mb-1 text-[10px] text-skino-orange-dark">နောက်တစ်ဆင့်</p><h2 class="text-base font-medium">သင့်အတွက် နေ့စဉ်ထိန်းသိမ်းမှု</h2></div></div><p class="mb-0 mt-3 text-[11px] leading-5 text-skino-muted">စကင်ရလဒ်အတိုင်း မနက်နှင့် ည လုပ်ဆောင်ချက်များကို တစ်ဆင့်ချင်း လုပ်ပြီး မှတ်တမ်းတင်နိုင်သည်။</p><div class="my-4 grid gap-2 sm:grid-cols-2"><div v-for="(step, index) in latestResult.treatment_package?.steps || ['cleanser','serum','moisturizer','sunscreen']" :key="`${step}-${index}`" class="flex items-center gap-3 rounded-xl bg-skino-paper p-3"><span class="grid size-11 shrink-0 place-items-center rounded-xl bg-white"><img class="size-10 object-contain" :src="routineTaskGroups[0].tasks[index % 4].image" alt="" /></span><span class="grid gap-1"><strong class="text-[11px] font-medium">{{ routineStepMy(step) }}</strong><small class="text-[9px] text-skino-muted">လုပ်ပြီးပါက နေ့စဉ်မှတ်တမ်းစာမျက်နှာတွင် မှတ်သားပါ</small></span></div></div><button class="min-h-11 w-full rounded-xl bg-skino-orange px-4 text-xs font-medium text-white hover:bg-skino-orange-dark disabled:opacity-40 sm:w-auto" type="button" :disabled="!latestResult.id || loading" @click="activateRoutine(latestResult)">နေ့စဉ်အစီအစဉ် စတင်မယ် →</button></article>

      <article class="flex flex-col gap-3 rounded-2xl border border-skino-line-orange bg-skino-paper p-4 sm:flex-row sm:items-center sm:p-5"><img class="size-14 object-contain" :src="specialistIcon" alt="" /><div class="flex-1"><h2 class="text-sm font-medium">ကျွမ်းကျင်သူ အကူအညီ လိုပါသလား?</h2><p class="mb-0 mt-1 text-[10px] leading-5 text-skino-muted">နာကျင်ခြင်း၊ မြန်မြန်ပြန့်ခြင်း သို့မဟုတ် မသေချာသော အခြေအနေရှိပါက ကျွမ်းကျင်သူထံ မေးမြန်းပါ။</p></div><button class="min-h-10 rounded-xl bg-skino-orange px-4 text-xs font-medium text-white" type="button" @click="openAppointment(latestResult)">ရက်ချိန်း တောင်းမယ်</button></article>
    </section>

    <section v-else-if="activeView === 'routine'" class="routine-view workspace-view mx-auto mt-4 grid max-w-6xl gap-3 sm:mt-6 sm:gap-4">
      <div class="workspace-page-heading"><button class="workspace-back" type="button" @click="openView('home')">‹ <span>ပင်မ</span></button><span class="workspace-page-icon"><img :src="routineIcon" alt="" /></span><div class="min-w-0"><p>နေ့စဉ် Routine</p><h1>ဒီနေ့ လုပ်ဆောင်ရမည့် Care စာရင်း</h1></div></div>

      <template v-if="routine">
        <article class="routine-calendar rounded-2xl border border-skino-line bg-white p-3 shadow-skino-sm sm:p-4"><div class="routine-calendar-heading"><div><p>ထိန်းသိမ်းမှု ပြက္ခဒိန်</p><h2>{{ routineCalendarTitle }}</h2></div><div class="routine-calendar-legend"><span><i class="bg-skino-green"></i>မနက်</span><span><i class="bg-skino-orange"></i>ည</span></div></div><div class="routine-calendar-scroll" tabindex="0" aria-label="Weekly routine calendar"><div class="routine-calendar-track"><div v-for="day in routineCalendarDays" :key="day.date" class="routine-calendar-day" :class="day.is_today ? 'today' : ''"><span>{{ day.label }}</span><b>{{ Number(day.date.slice(-2)) }}</b><small>{{ day.is_today ? 'ဒီနေ့' : ' ' }}</small><span class="routine-day-status"><i :class="day.morning_done ? 'bg-skino-green' : 'bg-skino-line'"></i><i :class="day.night_done ? 'bg-skino-orange' : 'bg-skino-line'"></i></span></div></div></div></article>

        <article class="routine-summary-card"><div><p>ဒီနေ့ Care Plan</p><h2>သင့်အတွက် နေ့စဉ် အသားအရေထိန်းသိမ်းမှု</h2><span>ပြီးစီးသောအဆင့်ကို ပြန်ဖြုတ်၍ မရပါ။ မနက်နှင့် ည လုပ်စရာများကို သေချာပြီးမှ မှတ်သားပါ။</span></div><div class="routine-progress-ring"><strong>{{ todayProgress }}%</strong><small>ဒီနေ့</small></div></article>

        <div class="routine-groups grid gap-3 sm:gap-4">
          <article v-for="group in routineTaskGroups" :key="group.key" class="min-w-0 rounded-2xl border border-skino-line bg-white p-3 shadow-skino-sm sm:p-4">
            <div class="mb-3 flex items-center justify-between gap-3"><div><h2 class="text-sm font-medium">{{ group.title }}</h2><p class="mb-0 mt-1 text-[9px] leading-4 text-skino-muted">{{ group.subtitle }}</p></div><span class="rounded-full px-2.5 py-1 text-[8px]" :class="routine.today?.[`${group.key}_done`] ? 'bg-emerald-50 text-skino-green' : 'bg-skino-orange-soft text-skino-orange-dark'">{{ routine.today?.[`${group.key}_done`] ? 'ပြီးစီးပါပြီ' : 'လုပ်ဆောင်ရန်' }}</span></div>
            <div class="grid gap-1.5"><button v-for="task in group.tasks" :key="task.key" class="routine-task grid min-h-[60px] grid-cols-[40px_1fr_26px] items-center gap-2.5 rounded-xl border p-2 text-left transition" :class="routineTaskDone(group, task) ? 'routine-task-done cursor-default border-emerald-200 bg-emerald-50' : 'border-skino-line bg-skino-paper hover:border-skino-line-orange'" type="button" :disabled="loading || routineTaskDone(group, task)" @click="toggleRoutineTask(group, task)"><span class="grid size-10 place-items-center rounded-lg bg-white"><img class="size-9 object-contain" :src="task.image" alt="" /></span><span class="grid gap-0.5"><strong class="text-[10px] font-medium">{{ task.title }}</strong><small class="text-[8px] leading-3.5 text-skino-muted">{{ task.note }}</small></span><span class="routine-check grid size-6 place-items-center rounded-full border text-[10px]" :class="routineTaskDone(group, task) ? 'border-skino-green bg-skino-green text-white' : 'border-skino-line bg-white text-skino-orange'">{{ routineTaskDone(group, task) ? '✓' : '○' }}</span></button></div>
          </article>
        </div>
        <div class="routine-stop-row"><p>Routine ကို ရပ်လိုက်လျှင် ယနေ့မပြီးသေးသော task များကို ဆက်မှတ်တမ်းတင်၍ မရတော့ပါ။</p><button type="button" @click="deactivateRoutine"><span aria-hidden="true">■</span> နေ့စဉ်အစီအစဉ် ရပ်မယ်</button></div>
      </template>

      <div v-else class="flex min-h-64 flex-col items-center justify-center gap-4 rounded-2xl border border-dashed border-skino-line-orange bg-skino-paper p-6 text-center"><img class="size-24 object-contain" :src="routineIcon" alt="" /><div><h2 class="text-lg font-medium">Routine မစတင်ရသေးပါ</h2><p class="my-2 text-xs leading-5 text-skino-muted">စကင်လုပ်ပြီး ရလဒ်အပေါ်မူတည်သော care plan ကို စတင်ပါ။</p><button class="min-h-11 rounded-xl bg-skino-orange px-4 text-xs font-medium text-white" type="button" @click="latestResult ? viewHistoryItem(latestResult) : openView('scan')">{{ latestResult ? 'နောက်ဆုံးရလဒ် ကြည့်မယ်' : 'စကင် စမယ်' }} →</button></div></div>
    </section>

    <section v-else-if="activeView === 'appointment'" class="workspace-view mx-auto mt-5 grid max-w-6xl gap-4 sm:mt-6">
      <div class="flex items-center justify-between gap-4 border-b border-skino-line pb-4">
        <div><button class="mb-2 text-[11px] text-skino-orange-dark transition hover:-translate-x-0.5" type="button" @click="openView('home')">‹ Modules</button><p class="text-[10px] font-medium uppercase tracking-[.14em] text-skino-orange-dark">Specialist care</p><h1 class="mt-1 text-2xl font-medium tracking-[-.025em] sm:text-3xl">Request a specialist review</h1><p class="mt-1 max-w-2xl text-xs leading-5 text-skino-muted">Choose a specialist and securely share a saved result for follow-up.</p></div><img class="size-16 object-contain sm:size-20" :src="specialistIcon" alt="" />
      </div>

      <div v-if="!latestResult" class="flex min-h-56 flex-col items-start justify-center gap-5 rounded-xl border border-dashed border-skino-line-orange bg-skino-paper p-6 sm:flex-row sm:items-center">
        <img class="size-24 object-contain" :src="scanIcon" alt="" /><div><h2 class="text-xl font-medium">A scan result is needed first.</h2><p class="my-2 text-xs text-skino-muted">The specialist request includes your skin type, score, severity, and visible concerns.</p><button class="min-h-10 rounded-lg bg-skino-orange px-4 text-xs font-medium text-white" type="button" @click="openView('scan')">Start a scan →</button></div>
      </div>

      <div v-else-if="appointmentSuccess" class="grid min-h-72 place-items-center rounded-xl border border-emerald-200 bg-emerald-50 p-6 text-center shadow-skino-sm">
        <div class="grid max-w-md place-items-center gap-3"><span class="grid size-14 place-items-center rounded-full bg-skino-green text-2xl text-white">✓</span><h2 class="text-2xl font-medium">Request sent.</h2><p class="text-sm leading-6 text-skino-muted">The Skino team can now review your scan summary and contact you using your preferred method.</p><div class="grid w-full gap-2 sm:grid-cols-2"><button class="min-h-11 rounded-lg bg-skino-orange px-4 text-xs font-medium text-white" type="button" @click="openView('home')">Back to dashboard</button><button class="min-h-11 rounded-lg border border-skino-line bg-white px-4 text-xs" type="button" @click="appointmentSuccess = null">Send another request</button></div></div>
      </div>

      <form v-else class="grid gap-4 lg:grid-cols-[.82fr_1.18fr]" @submit.prevent="submitAppointment">
        <div class="grid content-start gap-4">
          <article class="rounded-xl border border-skino-line bg-white p-5 shadow-skino-sm">
            <p class="mb-3 text-[11px] font-medium uppercase tracking-[.14em] text-skino-orange-dark">Choose specialist</p>
            <div class="grid gap-2">
              <button v-for="specialist in specialistProfiles" :key="specialist.name" class="grid min-h-20 grid-cols-[44px_1fr_auto] items-center gap-3 rounded-lg border p-3 text-left transition" :class="appointmentForm.requestedSpecialist === specialist.name ? 'border-skino-orange bg-skino-orange-soft' : 'border-skino-line hover:border-skino-line-orange'" type="button" @click="appointmentForm.requestedSpecialist = specialist.name">
                <span class="grid size-11 place-items-center rounded-lg text-xs font-medium" :class="specialist.tone">{{ specialist.name.split(' ').slice(1).map((part) => part[0]).join('') }}</span><span class="grid gap-0.5"><strong class="text-xs font-medium">{{ specialist.name }}</strong><small class="text-[10px] text-skino-muted">{{ specialist.role }}</small></span><small class="max-w-20 text-right text-[9px] leading-4 text-skino-muted">{{ specialist.schedule }}</small>
              </button>
            </div>
          </article>

          <article class="rounded-xl border border-skino-line bg-white p-5 shadow-skino-sm">
            <label class="grid gap-2 text-xs"><span class="font-medium">Scan for this request</span><select v-model="appointmentScanId" class="min-h-11 rounded-lg border border-skino-line bg-white px-3 text-xs outline-none focus:border-skino-orange"><option v-for="scan in history" :key="scan.id" :value="String(scan.id)">{{ formatDate(scan.created_at) }} · {{ scan.skin_type }} · score {{ scan.skin_health_score }}</option></select></label>
            <div v-if="selectedAppointmentScan" class="mt-4 grid grid-cols-3 gap-2 rounded-lg bg-skino-paper p-3 text-center"><span class="grid gap-0.5"><b class="text-lg font-medium text-skino-orange">{{ selectedAppointmentScan.skin_health_score }}</b><small class="text-[9px] text-skino-muted">Score</small></span><span class="grid gap-0.5"><b class="text-xs font-medium capitalize">{{ selectedAppointmentScan.skin_type }}</b><small class="text-[9px] text-skino-muted">Skin type</small></span><span class="grid gap-0.5"><b class="text-xs font-medium capitalize">{{ selectedAppointmentScan.acne_severity }}</b><small class="text-[9px] text-skino-muted">Severity</small></span></div>
          </article>
        </div>

        <article class="rounded-xl border border-skino-line bg-white p-5 shadow-skino-sm sm:p-6">
          <p class="mb-4 text-[11px] font-medium uppercase tracking-[.14em] text-skino-orange-dark">Contact and request</p>
          <div class="grid gap-4 sm:grid-cols-2">
            <label class="grid gap-2 text-xs"><span class="font-medium">Name</span><input v-model.trim="appointmentForm.name" class="min-h-11 rounded-lg border border-skino-line px-3 outline-none focus:border-skino-orange" maxlength="120" required /></label>
            <label class="grid gap-2 text-xs"><span class="font-medium">Email</span><input v-model.trim="appointmentForm.email" class="min-h-11 rounded-lg border border-skino-line px-3 outline-none focus:border-skino-orange" type="email" maxlength="255" /></label>
            <label class="grid gap-2 text-xs"><span class="font-medium">Phone</span><input v-model.trim="appointmentForm.phone" class="min-h-11 rounded-lg border border-skino-line px-3 outline-none focus:border-skino-orange" type="tel" maxlength="40" placeholder="Optional when email is provided" /></label>
            <label class="grid gap-2 text-xs"><span class="font-medium">Preferred contact</span><select v-model="appointmentForm.preferredContactMethod" class="min-h-11 rounded-lg border border-skino-line bg-white px-3 outline-none focus:border-skino-orange"><option value="in_app">In app / email</option><option value="phone">Phone</option><option value="viber">Viber</option><option value="telegram">Telegram</option><option value="email">Email</option></select></label>
            <label class="grid gap-2 text-xs"><span class="font-medium">Preferred date</span><input v-model="appointmentForm.preferredDate" class="min-h-11 rounded-lg border border-skino-line px-3 outline-none focus:border-skino-orange" type="date" :min="new Date().toISOString().slice(0, 10)" /></label>
            <label class="grid gap-2 text-xs"><span class="font-medium">Beauty goal</span><input v-model.trim="appointmentForm.beautyGoal" class="min-h-11 rounded-lg border border-skino-line px-3 outline-none focus:border-skino-orange" maxlength="160" /></label>
            <label class="grid gap-2 text-xs sm:col-span-2"><span class="font-medium">Notes for specialist</span><textarea v-model.trim="appointmentForm.notes" class="min-h-28 resize-y rounded-lg border border-skino-line p-3 leading-5 outline-none focus:border-skino-orange" maxlength="2000" placeholder="Share irritation, products you use, or what you want help with."></textarea></label>
          </div>
          <div class="mt-5 rounded-lg border border-amber-200 bg-amber-50 p-3 text-[11px] leading-5 text-skino-muted">This sends a consultation request, not an emergency or medical diagnosis. Seek urgent medical help for severe pain, breathing difficulty, or rapidly spreading symptoms.</div>
          <button class="mt-4 inline-flex min-h-11 w-full items-center justify-center gap-2 rounded-lg bg-skino-orange px-4 text-xs font-medium text-white shadow-skino-sm hover:bg-skino-orange-dark disabled:opacity-40" type="submit" :disabled="appointmentLoading"><i v-if="appointmentLoading" class="button-spinner light"></i>{{ appointmentLoading ? 'Sending request…' : 'Send appointment request →' }}</button>
        </article>
      </form>
    </section>

    <section v-else-if="activeView === 'history'" class="workspace-view mx-auto mt-5 grid max-w-6xl gap-4 sm:mt-6">
      <div class="flex items-center justify-between gap-4 border-b border-skino-line pb-4"><div><button class="mb-2 text-[11px] text-skino-orange-dark transition hover:-translate-x-0.5" type="button" @click="openView('home')">‹ Modules</button><p class="text-[10px] font-medium uppercase tracking-[.14em] text-skino-orange-dark">Scan history</p><h1 class="mt-1 text-2xl font-medium tracking-[-.025em] sm:text-3xl">Saved skin results</h1><p class="mt-1 text-xs text-skino-muted">Review progress and revisit any previous scan.</p></div><img class="size-16 object-contain sm:size-20" :src="progressIcon" alt="" /></div>
      <div v-if="history.length" class="grid gap-3 lg:grid-cols-2"><article v-for="item in history" :key="item.id" class="grid grid-cols-[64px_1fr] items-center gap-3 rounded-xl border border-skino-line bg-white p-4 shadow-skino-sm sm:grid-cols-[70px_1fr_auto]"><div class="grid size-16 place-items-center content-center rounded-full bg-skino-orange text-white"><strong class="text-2xl font-medium">{{ item.skin_health_score }}</strong><small class="text-[9px] text-white/70">Score</small></div><div class="grid gap-0.5"><span class="text-[10px] text-skino-muted">{{ formatDate(item.created_at) }}</span><h2 class="text-sm font-medium capitalize">{{ item.skin_type }} skin</h2><p class="text-[10px] text-skino-muted">{{ item.acne_severity }} acne · {{ item.concerns?.length || 0 }} concerns</p></div><div class="col-span-2 grid grid-cols-2 gap-1 sm:col-span-1 sm:grid-cols-1"><button class="min-h-8 rounded border border-skino-line px-2 text-[10px]" type="button" @click="viewHistoryItem(item)">View result</button><button class="min-h-8 rounded border border-red-100 px-2 text-[10px] text-red-700" type="button" @click="removeHistoryItem(item)">Delete</button></div></article></div>
      <div v-else class="flex min-h-56 flex-col items-start justify-center gap-5 rounded-xl border border-dashed border-skino-line-orange bg-skino-paper p-6 sm:flex-row sm:items-center"><img class="size-24 object-contain" :src="historyIcon" alt="" /><div><h2 class="text-xl font-medium">No saved scans yet.</h2><p class="my-2 text-xs text-skino-muted">Your first authenticated scan will appear here automatically.</p><button class="min-h-10 rounded-lg bg-skino-orange px-4 text-xs font-medium text-white" type="button" @click="openView('scan')">Start a scan →</button></div></div>
    </section>

    <nav class="workspace-mobile-nav" aria-label="Workspace navigation"><button type="button" :class="{ active: activeView === 'home' }" @click="openView('home')"><span>⌂</span>ပင်မ</button><button type="button" :class="{ active: ['scan','result'].includes(activeView) }" @click="openView('scan')"><span>◎</span>စကင်</button><button type="button" :class="{ active: activeView === 'routine' }" @click="openView('routine')"><span>✓</span>Routine</button><button type="button" :class="{ active: activeView === 'history' }" @click="openView('history')"><span>◷</span>မှတ်တမ်း</button><button type="button" :class="{ active: activeView === 'profile' }" @click="openView('profile')"><span>○</span>Profile</button></nav>

  </main>
</template>
