<script setup>
import { computed, nextTick, onMounted, onUnmounted, ref, watch } from 'vue'
import UserWorkspace from './components/UserWorkspace.vue'
import PricingPlans from './components/PricingPlans.vue'
import {
  clearSession,
  fetchMe,
  fetchRequiredConsents,
  fetchTrainingConsent,
  googleClientId,
  loadGoogleIdentity,
  loginWithGoogle,
  loginWithPassword,
  logout,
  readSession,
  saveSession,
  updateTrainingConsent,
  updateRequiredConsents,
} from './services/skinoApi'
import logo from './assets/branding/skino_logo.webp'
import waveMascot from './assets/branding/skino_little_guy_wave.png'
import careMascot from './assets/branding/skino_little_guy_care.png'
import specialistSlide from './assets/branding/hero-slide-specialist.jpg'
import analysisSlide from './assets/branding/hero-slide-analysis.jpg'
import routineSlide from './assets/branding/hero-slide-routine.jpg'
import scanIcon from './assets/branding/skino_icon_scan.png'
import routineIcon from './assets/branding/skino_icon_routine.png'
import specialistIcon from './assets/branding/skino_icon_specialist.png'
import historyIcon from './assets/branding/skino_icon_history.webp'
import progressIcon from './assets/branding/skino_icon_progress.webp'
import reportIcon from './assets/branding/skino_icon_report.webp'

const activeView = ref('home')
const isLoggedIn = ref(false)
const onboardingComplete = ref(false)
const onboardingStep = ref(0)
const language = ref('en')
const mobileMenuOpen = ref(false)
const showStickyActions = ref(false)
const isHeaderCompact = ref(false)
const motionReady = ref(false)
const currentPublicSection = ref('home')
const journeyProgress = ref(0)
const acceptedTerms = ref(false)
const acceptedScanConsent = ref(false)
const allowModelTraining = ref(false)
const showPassword = ref(false)
const session = ref(null)
const authLoading = ref(false)
const authError = ref('')
const onboardingError = ref('')
const googleButton = ref(null)
const loginForm = ref({ email: '', password: '', remember: true })
const currentHeroSlide = ref(0)
const heroTouchStartX = ref(0)
let heroSliderTimer = null
let googleIdentityInitialized = false
let revealObserver = null

const copy = {
  en: {
    home: 'Home', services: 'Services', how: 'How it works', safety: 'Safety', about: 'About Us', contact: 'Contact Us', login: 'Sign in',
    eyebrow: 'Skino / Personal skin intelligence',
    heroTitle: ['Your skin has a story.', 'Skino listens.'],
    heroBody: 'Scan your skin, understand visible concerns, and build a routine that is simple enough to follow every day.',
    startScan: 'Start skin scan', exploreServices: 'See how it works', scanReady: 'Face scan ready', scanHint: 'Clear light · Front view · No filter',
    howTitle: 'Clear care in three small steps.', howText: 'No complicated setup. Start with one scan and always know what comes next.',
    serviceTitle: 'Everything your skin journey needs.', serviceText: 'Compact tools that work together—from the first scan to daily progress.',
    safetyTitle: 'Smart AI. Clear limits.', safetyText: 'Skino gives care guidance, protects your choices, and tells you when professional help matters.',
    routineTitle: 'A routine made for real life.', routineText: 'Simple morning and evening steps, gentle reminders, and progress you can actually see.',
    progressTitle: 'Small habits. Visible momentum.', aboutTitle: 'Skincare guidance should feel calm and clear.',
    aboutText: 'Team Kairo built Skino as a wellness and skincare assistant—not a medical diagnosis system. Your choices stay visible and under your control.',
    ctaTitle: 'Ready to understand your skin?', ctaText: 'Your first guided scan starts with a quick privacy check.',
    loginTitle: 'Welcome back.', loginText: 'Sign in to continue your private skincare journey.', email: 'Email address', password: 'Password',
    remember: 'Keep me signed in', forgot: 'Forgot password?', loginButton: 'Continue to Skino', backHome: 'Back to home',
    secureNote: 'Your account and scan history stay private.', dashboardHello: 'Good morning, May', dashboardText: 'Your skin plan is ready. Keep today simple.', logout: 'Sign out',
  },
  my: {
    home: 'ပင်မ', services: 'ဝန်ဆောင်မှု', how: 'အသုံးပြုပုံ', safety: 'လုံခြုံမှု', about: 'အကြောင်း', contact: 'ဆက်သွယ်ရန်', login: 'ဝင်မယ်',
    eyebrow: 'Skino / ကိုယ်ပိုင် skin intelligence', heroTitle: ['သင့် skin မှာ ဇာတ်လမ်းရှိတယ်။', 'Skino နားထောင်တယ်။'],
    heroBody: 'Skin scan လုပ်၊ မြင်ရသော concern များကို နားလည်ပြီး နေ့တိုင်း လိုက်လုပ်နိုင်မည့် ရိုးရှင်းသော routine တည်ဆောက်ပါ။',
    startScan: 'Skin scan စမယ်', exploreServices: 'အသုံးပြုပုံကြည့်မယ်', scanReady: 'Face scan အဆင်သင့်', scanHint: 'အလင်းကောင်း · မျက်နှာတည့်တည့် · Filter မပါ',
    howTitle: 'အဆင့်သုံးဆင့်နဲ့ ရှင်းလင်းသော care.', howText: 'ရှုပ်ထွေးတဲ့ setup မလိုပါ။ Scan တစ်ခုပြီးရင် နောက်တစ်ဆင့်ကို အမြဲသိနိုင်ပါတယ်။',
    serviceTitle: 'သင့် skin journey အတွက် လိုအပ်သမျှ။', serviceText: 'ပထမ scan မှ နေ့စဉ် progress အထိ အတူတကွ အလုပ်လုပ်သော tools များ။',
    safetyTitle: 'Smart AI. ရှင်းလင်းသော limits.', safetyText: 'Skino က care guidance ပေးပြီး သင့်ရွေးချယ်မှုကို ကာကွယ်ကာ professional help လိုအပ်ချိန်ကို ပြောပြပါတယ်။',
    routineTitle: 'တကယ်လိုက်လုပ်နိုင်မည့် routine.', routineText: 'ရိုးရှင်းသော မနက်/ည steps၊ နူးညံ့သော reminder များနှင့် မြင်နိုင်သော progress။',
    progressTitle: 'အလေ့အကျင့်သေးသေး။ မြင်သာတဲ့တိုးတက်မှု။', aboutTitle: 'Skincare guidance က ငြိမ်သက်ပြီး နားလည်လွယ်ရမယ်။',
    aboutText: 'Team Kairo က Skino ကို wellness နဲ့ skincare assistant အဖြစ် တည်ဆောက်ထားပါတယ်—medical diagnosis system မဟုတ်ပါ။',
    ctaTitle: 'သင့် skin ကို နားလည်ဖို့ အဆင်သင့်လား?', ctaText: 'ပထမ guided scan ကို privacy check အတိုလေးနဲ့ စပါမယ်။',
    loginTitle: 'ပြန်လည်ကြိုဆိုပါတယ်။', loginText: 'သင့် private skincare journey ကို ဆက်ရန် sign in ဝင်ပါ။', email: 'Email address', password: 'Password',
    remember: 'Login မှတ်ထားမယ်', forgot: 'Password မေ့နေပါသလား?', loginButton: 'Skino သို့ ဆက်မယ်', backHome: 'ပင်မသို့ ပြန်မယ်',
    secureNote: 'သင့် account နှင့် scan history ကို private ထားပါတယ်။', dashboardHello: 'မင်္ဂလာနံနက်ခင်းပါ May', dashboardText: 'ဒီနေ့ skin plan အဆင်သင့်ပါပြီ။ ရိုးရိုးရှင်းရှင်း ဆက်လုပ်ပါ။', logout: 'ထွက်မယ်',
  },
}

const t = computed(() => copy[language.value])
const navItems = computed(() => [
  { label: t.value.home, target: 'home' },
  { label: t.value.services, target: 'services' },
  { label: t.value.about, target: 'about' },
  { label: t.value.contact, target: 'contact' },
])
const heroSlides = [
  { image: specialistSlide, eyebrow: 'Specialist support', title: 'Expert care when you need it.', text: 'Share a saved skin result and request a focused specialist review.' },
  { image: analysisSlide, eyebrow: 'AI skin insights', title: 'Understand every visible signal.', text: 'See concerns and face-zone details in language that is easy to follow.' },
  { image: routineSlide, eyebrow: 'Daily routine', title: 'Turn results into simple care.', text: 'Build a gentle morning and night routine around your latest scan.' },
]
const steps = computed(() => [
  { number: '01', title: 'Scan', text: language.value === 'en' ? 'Use a clear front-facing photo.' : 'မျက်နှာတည့်တည့် ပုံကြည်ကြည် သုံးပါ။', icon: scanIcon },
  { number: '02', title: language.value === 'en' ? 'Understand' : 'နားလည်', text: language.value === 'en' ? 'See concerns in plain language.' : 'Concern များကို ရိုးရှင်းစွာ ကြည့်ပါ။', icon: reportIcon },
  { number: '03', title: language.value === 'en' ? 'Care' : 'ဂရုစိုက်', text: language.value === 'en' ? 'Follow a gentle daily routine.' : 'နူးညံ့သော daily routine ကို လိုက်လုပ်ပါ။', icon: routineIcon },
])
const modules = computed(() => language.value === 'en' ? [
  { title: 'Guided face scan', subtitle: 'Camera guidance helps you capture a clear, front-facing photo before analysis.', icon: scanIcon, status: 'Start here', tone: '#f36a16', feature: 'Camera + quality check' },
  { title: 'Clear skin results', subtitle: 'Understand your score, visible concerns, and each facial zone without confusing medical language.', icon: reportIcon, status: 'Understand', tone: '#7c65b5', feature: 'Score + skin map' },
  { title: 'Daily care routine', subtitle: 'Turn your latest result into small morning and evening tasks you can actually track.', icon: routineIcon, status: 'Take action', tone: '#0e5c56', feature: 'To-do + weekly record' },
  { title: 'History, safety and support', subtitle: 'Revisit saved scans, control your privacy choices, or share a result when specialist support matters.', icon: specialistIcon, status: 'Stay supported', tone: '#38748f', feature: 'History + privacy + specialist' },
] : [
  { title: 'လမ်းညွှန်ပါ မျက်နှာစကင်', subtitle: 'မစစ်ဆေးမီ ရှေ့တည့်တည့် ကြည်လင်သောပုံရရန် ကင်မရာလမ်းညွှန်ပေးပါသည်။', icon: scanIcon, status: 'ဒီမှာစမယ်', tone: '#f36a16', feature: 'ကင်မရာ + အရည်အသွေးစစ်ဆေးမှု' },
  { title: 'ရှင်းလင်းသော ရလဒ်', subtitle: 'ရှုပ်ထွေးသော ဆေးဘက်ဝေါဟာရမပါဘဲ အမှတ်၊ မြင်ရသောအချက်နှင့် မျက်နှာနေရာခွဲကို နားလည်ပါ။', icon: reportIcon, status: 'နားလည်မယ်', tone: '#7c65b5', feature: 'အမှတ် + အသားအရေမြေပုံ' },
  { title: 'နေ့စဉ် ထိန်းသိမ်းမှု', subtitle: 'နောက်ဆုံးရလဒ်ကို မှတ်တမ်းတင်နိုင်သော မနက်နှင့် ည လုပ်ဆောင်ချက်ငယ်များအဖြစ် ပြောင်းပါ။', icon: routineIcon, status: 'စလုပ်မယ်', tone: '#0e5c56', feature: 'လုပ်စရာ + အပတ်စဉ်မှတ်တမ်း' },
  { title: 'မှတ်တမ်း၊ လုံခြုံမှုနှင့် အကူအညီ', subtitle: 'သိမ်းထားသောစကင်ကို ပြန်ကြည့်၊ privacy ကို ထိန်းချုပ် သို့မဟုတ် ကျွမ်းကျင်သူထံ ရလဒ်မျှဝေပါ။', icon: specialistIcon, status: 'အကူအညီရမယ်', tone: '#38748f', feature: 'မှတ်တမ်း + privacy + ကျွမ်းကျင်သူ' },
])
const onboardingPages = [
  {
    kicker: 'Welcome / 01',
    title: 'Meet your private skin companion.',
    titleMy: 'သင့်ကိုယ်ပိုင် အသားအရေ အဖော် Skino',
    body: 'Skino connects one guided face scan to understandable results, a practical daily routine, and progress you can revisit.',
    bodyMy: 'လမ်းညွှန်ထားသော မျက်နှာစကင်မှ နားလည်လွယ်သည့် ရလဒ်၊ နေ့စဉ်လုပ်စရာနှင့် တိုးတက်မှုမှတ်တမ်းအထိ တစ်နေရာတည်းတွင် အသုံးပြုနိုင်ပါသည်။',
    image: waveMascot,
  },
  {
    kicker: 'Safe scan / 02',
    title: 'A clear photo makes a better demo.',
    titleMy: 'ပုံကြည်လင်လေ ရလဒ်ပိုကောင်းလေ',
    body: 'Use even light, face the camera directly, remove filters, and keep your whole face visible. Skino selects the clearest of three captured frames.',
    bodyMy: 'အလင်းညီညာစွာထားပြီး ကင်မရာကို တည့်တည့်ကြည့်ပါ။ Filter မသုံးဘဲ မျက်နှာအပြည့်မြင်ရပါမည်။ ရိုက်ထားသော frame သုံးခုထဲမှ အကြည်ဆုံးပုံကို ရွေးပေးပါသည်။',
    image: scanIcon,
  },
  {
    kicker: 'Consent / 03',
    title: 'Your face. Your permission. Your control.',
    titleMy: 'သင့်မျက်နှာ၊ သင့်ခွင့်ပြုချက်၊ သင့်ဆုံးဖြတ်ချက်',
    body: 'A face photo can be sensitive. Required choices enable your requested scan; optional model-learning remains off unless you choose it.',
    bodyMy: 'မျက်နှာပုံသည် အရေးကြီးသော ကိုယ်ရေးဒေတာဖြစ်နိုင်ပါသည်။ စကင်လုပ်ရန် လိုအပ်သော ခွင့်ပြုချက်များကိုသာ မဖြစ်မနေတောင်းပြီး AI လေ့လာရေးကို သင်ရွေးမှသာ ဖွင့်ပါမည်။',
    image: reportIcon,
  },
]
const onboardingConsents = [
  { key: 'terms', icon: historyIcon, title: 'Terms & Privacy', titleMy: 'စည်းမျဉ်းနှင့် ကိုယ်ရေးလုံခြုံမှု', text: 'I agree to the service terms and understand how my account, scan, and routine data are handled.', textMy: 'ဝန်ဆောင်မှုစည်းမျဉ်းကို သဘောတူပြီး account၊ scan နှင့် routine ဒေတာကို မည်သို့ကိုင်တွယ်သည်ကို နားလည်ပါသည်။', badge: 'Required' },
  { key: 'scan', icon: scanIcon, title: 'Face-scan processing', titleMy: 'မျက်နှာစကင် စစ်ဆေးခွင့်', text: 'I allow my selected photo to be processed for skin analysis, result display, and care guidance. This is not medical advice.', textMy: 'ရွေးထားသောပုံကို အသားအရေစစ်ဆေးမှု၊ ရလဒ်ပြသမှုနှင့် care guidance အတွက် အသုံးပြုခွင့်ပေးပါသည်။ ဆေးဘက်ဆိုင်ရာ diagnosis မဟုတ်ပါ။', badge: 'Required' },
  { key: 'training', icon: progressIcon, title: 'Help improve Skino AI', titleMy: 'Skino AI တိုးတက်ရေးတွင် ပါဝင်မယ်', text: 'Allow an eligible scan to enter a review queue for future model improvement. You can turn this off later.', textMy: 'သင့်တော်သော scan ကို နောက်ပိုင်း model တိုးတက်ရေးအတွက် review queue သို့ ပို့ခွင့်ပေးပါသည်။ Profile မှ အချိန်မရွေး ပိတ်နိုင်ပါသည်။', badge: 'Optional' },
]
const currentOnboarding = computed(() => onboardingPages[onboardingStep.value])
const isLastOnboardingStep = computed(() => onboardingStep.value === onboardingPages.length - 1)
const canFinishOnboarding = computed(() => acceptedTerms.value && acceptedScanConsent.value)

function scrollTo(target) {
  activeView.value = target
  currentPublicSection.value = target
  mobileMenuOpen.value = false
  nextTick(() => {
    if (target === 'home') { window.scrollTo({ top: 0, behavior: 'smooth' }); return }
    document.getElementById(target)?.scrollIntoView({ behavior: 'smooth', block: 'start' })
  })
}
function choosePublicPlan() { openLogin() }
function openLogin() { activeView.value = 'login'; mobileMenuOpen.value = false; window.scrollTo({ top: 0, behavior: 'smooth' }) }
function openLegal(view) { activeView.value = view; mobileMenuOpen.value = false; window.scrollTo({ top: 0, behavior: 'smooth' }) }
function startHeroSlider() {
  window.clearInterval(heroSliderTimer)
  heroSliderTimer = window.setInterval(() => { currentHeroSlide.value = (currentHeroSlide.value + 1) % heroSlides.length }, 5200)
}
function stopHeroSlider() { window.clearInterval(heroSliderTimer) }
function goToHeroSlide(index) {
  currentHeroSlide.value = (index + heroSlides.length) % heroSlides.length
  startHeroSlider()
}
function handleHeroTouchStart(event) { heroTouchStartX.value = event.touches[0]?.clientX || 0 }
function handleHeroTouchEnd(event) {
  const distance = (event.changedTouches[0]?.clientX || 0) - heroTouchStartX.value
  if (Math.abs(distance) > 45) goToHeroSlide(currentHeroSlide.value + (distance < 0 ? 1 : -1))
}
function onboardingKey(userId = session.value?.user?.id) { return `skino.web.onboarding.${userId || 'guest'}` }
async function applySession(nextSession) {
  session.value = nextSession
  saveSession(nextSession)
  isLoggedIn.value = true
  onboardingStep.value = 0
  const [requiredResult, trainingResult] = await Promise.allSettled([
    fetchRequiredConsents(nextSession.token),
    fetchTrainingConsent(nextSession.token),
  ])
  onboardingComplete.value = requiredResult.status === 'fulfilled' && requiredResult.value?.complete === true
  allowModelTraining.value = trainingResult.status === 'fulfilled' && trainingResult.value?.granted === true
  window.scrollTo({ top: 0 })
}
async function enterDashboard() {
  if (authLoading.value) return
  authLoading.value = true
  authError.value = ''
  try {
    await applySession(await loginWithPassword(loginForm.value.email.trim(), loginForm.value.password))
  } catch (error) {
    authError.value = friendlyAuthError(error)
  } finally {
    authLoading.value = false
  }
}
async function handleGoogleCredential(response) {
  authLoading.value = true
  authError.value = ''
  try {
    await applySession(await loginWithGoogle(response.credential))
  } catch (error) {
    authError.value = friendlyAuthError(error)
  } finally {
    authLoading.value = false
  }
}
async function setupGoogleButton() {
  if (activeView.value !== 'login') return
  await nextTick()
  if (!googleButton.value) return
  googleButton.value.innerHTML = ''
  if (!googleClientId) return
  try {
    const google = await loadGoogleIdentity()
    if (!googleIdentityInitialized) {
      google.accounts.id.initialize({ client_id: googleClientId, callback: handleGoogleCredential, auto_select: false })
      googleIdentityInitialized = true
    }
    google.accounts.id.renderButton(googleButton.value, { theme: 'outline', size: 'large', shape: 'pill', width: Math.min(350, googleButton.value.clientWidth || 350), text: 'continue_with' })
  } catch (error) {
    authError.value = 'Google sign-in is temporarily unavailable. Please continue with email or try again.'
  }
}
function friendlyAuthError(error) {
  const message = String(error?.message || '')
  if (/credential|email|password|unauthenticated|401/i.test(message)) return 'We could not sign you in with those details. Check them and try again.'
  if (/network|fetch|load|connect/i.test(message)) return 'Skino could not reach the server. Check your connection and try again.'
  return 'Sign-in could not be completed. Please try again in a moment.'
}
async function nextOnboardingStep() {
  if (!isLastOnboardingStep.value) { onboardingStep.value += 1; return }
  if (!canFinishOnboarding.value) return
  authLoading.value = true
  onboardingError.value = ''
  try {
    await Promise.all([
      updateRequiredConsents(session.value.token, { terms: true, scan_processing: true }),
      updateTrainingConsent(session.value.token, allowModelTraining.value),
    ])
    onboardingComplete.value = true
    localStorage.removeItem(onboardingKey())
    window.scrollTo({ top: 0 })
  } catch {
    onboardingError.value = 'We could not save your privacy choices. Check your connection and try again—nothing has been submitted yet.'
  } finally {
    authLoading.value = false
  }
}
function previousOnboardingStep() { if (onboardingStep.value > 0) onboardingStep.value -= 1 }
function updateSessionProfile(user) {
  session.value = { ...session.value, user }
  saveSession(session.value)
}
function updateTrainingChoice(granted) { allowModelTraining.value = granted }
async function signOut() {
  const token = session.value?.token
  if (token) logout(token).catch(() => {})
  clearSession()
  session.value = null
  isLoggedIn.value = false; onboardingComplete.value = false; activeView.value = 'home'; acceptedTerms.value = false
  acceptedScanConsent.value = false; allowModelTraining.value = false; window.scrollTo({ top: 0 })
}
function syncPublicMotion() {
  const scrollTop = window.scrollY
  showStickyActions.value = scrollTop > 480
  isHeaderCompact.value = scrollTop > 36

  const sections = ['home', 'how', 'services', 'about', 'contact']
    .map((id) => document.getElementById(id))
    .filter(Boolean)
  const marker = window.innerHeight * 0.38
  currentPublicSection.value = sections.reduce((current, section) => (
    section.getBoundingClientRect().top <= marker ? section.id : current
  ), 'home')

  const journey = document.querySelector('.how-journey')
  if (journey) {
    const rect = journey.getBoundingClientRect()
    journeyProgress.value = Math.min(1, Math.max(0, (window.innerHeight * 0.76 - rect.top) / Math.max(rect.height * 0.78, 1)))
  }
}

async function setupPublicMotion() {
  await nextTick()
  revealObserver?.disconnect()
  const targets = document.querySelectorAll('.reveal-on-scroll')
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches
  motionReady.value = true
  if (reduceMotion || !('IntersectionObserver' in window)) {
    targets.forEach((target) => target.classList.add('is-visible'))
  } else {
    revealObserver = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (!entry.isIntersecting) return
        entry.target.classList.add('is-visible')
        revealObserver?.unobserve(entry.target)
      })
    }, { threshold: 0.13, rootMargin: '0px 0px -7% 0px' })
    targets.forEach((target) => revealObserver.observe(target))
  }
  syncPublicMotion()
}

watch(activeView, (view) => {
  if (view === 'login') setupGoogleButton()
  else if (!isLoggedIn.value) setupPublicMotion()
})
onMounted(async () => {
  window.addEventListener('scroll', syncPublicMotion, { passive: true })
  startHeroSlider()
  setupPublicMotion()
  const savedSession = readSession()
  if (!savedSession?.token) return
  try {
    const user = await fetchMe(savedSession.token)
    await applySession({ ...savedSession, user })
  } catch {
    clearSession()
  }
})
onUnmounted(() => {
  window.removeEventListener('scroll', syncPublicMotion)
  window.clearInterval(heroSliderTimer)
  revealObserver?.disconnect()
})
</script>

<template>
  <div class="app-shell" :class="{ 'motion-ready': motionReady }">
    <template v-if="!isLoggedIn">
      <header class="site-header" :class="{ 'is-scrolled': isHeaderCompact }">
        <button class="brand-button" type="button" aria-label="Skino home" @click="scrollTo('home')"><img :src="logo" alt="" /><span>Skino<small>Skin intelligence</small></span></button>
        <button class="menu-button" type="button" :aria-expanded="mobileMenuOpen" aria-label="Toggle navigation" @click="mobileMenuOpen = !mobileMenuOpen"><span></span><span></span></button>
        <nav :class="['nav-links', { open: mobileMenuOpen }]" aria-label="Primary navigation">
          <button v-for="item in navItems" :key="item.target" type="button" :class="{ active: currentPublicSection === item.target && activeView !== 'login' }" @click="scrollTo(item.target)">{{ item.label }}</button>
          <div class="mobile-language-nav"><button type="button" :class="{ active: language === 'en' }" @click="language = 'en'">English</button><button type="button" :class="{ active: language === 'my' }" @click="language = 'my'">မြန်မာ</button></div>
          <button class="mobile-login-nav" type="button" @click="openLogin">{{ t.login }} <span>→</span></button>
        </nav>
        <div class="header-actions"><div class="language-toggle" aria-label="Language"><button type="button" :class="{ active: language === 'en' }" @click="language = 'en'">EN</button><button type="button" :class="{ active: language === 'my' }" @click="language = 'my'">မြန်မာ</button></div><button class="signin-button" type="button" :class="{ 'is-current': activeView === 'login' }" @click="openLogin"><span class="signin-dot"></span>{{ t.login }} <i>→</i></button></div>
      </header>

      <main v-if="!['login', 'terms', 'privacy'].includes(activeView)" class="public-main">
        <section id="home" class="hero-section">
          <div class="hero-copy"><p class="eyebrow">{{ t.eyebrow }}</p><h1><span>{{ t.heroTitle[0] }}</span><span>{{ t.heroTitle[1] }}</span></h1><p class="hero-body">{{ t.heroBody }}</p><div class="hero-actions"><button class="primary-button" type="button" @click="openLogin">{{ t.startScan }} <span>→</span></button><button class="text-button" type="button" @click="scrollTo('how')">{{ t.exploreServices }}</button></div><div class="trust-row"><span>Private by default</span><span>Guidance, not diagnosis</span><span>Mobile ready</span></div></div>
          <div class="hero-slider" aria-roledescription="carousel" aria-label="Skino care highlights" @mouseenter="stopHeroSlider" @mouseleave="startHeroSlider" @touchstart.passive="handleHeroTouchStart" @touchend="handleHeroTouchEnd">
            <div class="hero-slider-track">
              <article v-for="(slide, index) in heroSlides" :key="slide.title" class="hero-slide" :class="{ active: index === currentHeroSlide }" :aria-hidden="index !== currentHeroSlide">
                <img :src="slide.image" :alt="slide.title" />
                <div class="hero-slide-shade"></div>
                <div class="hero-slide-copy"><span>{{ slide.eyebrow }}</span><h2>{{ slide.title }}</h2><p>{{ slide.text }}</p></div>
              </article>
            </div>
            <button class="slider-arrow slider-arrow-left" type="button" aria-label="Previous slide" @click="goToHeroSlide(currentHeroSlide - 1)">‹</button>
            <button class="slider-arrow slider-arrow-right" type="button" aria-label="Next slide" @click="goToHeroSlide(currentHeroSlide + 1)">›</button>
            <div class="slider-dots" aria-label="Choose slide"><button v-for="(_, index) in heroSlides" :key="index" type="button" :class="{ active: index === currentHeroSlide }" :aria-label="`Show slide ${index + 1}`" @click="goToHeroSlide(index)"></button></div>
          </div>
        </section>

        <section id="how" class="content-section how-section reveal-on-scroll">
          <div class="section-heading split-heading"><div><p class="eyebrow">01 / How it works</p><h2>{{ t.howTitle }}</h2></div><p>{{ t.howText }}</p></div>
          <div class="how-journey" :style="{ '--journey-progress': journeyProgress }">
            <div class="journey-path" aria-hidden="true"><span></span></div>
            <article v-for="(step, index) in steps" :key="step.number" class="journey-step" :class="`journey-step-${index + 1}`"><div class="journey-icon"><img :src="step.icon" alt="" /><span>{{ step.number }}</span></div><div><small>{{ index === 0 ? 'CAPTURE' : index === 1 ? 'UNDERSTAND' : 'BUILD A HABIT' }}</small><h3>{{ step.title }}</h3><p>{{ step.text }}</p></div></article>
            <div class="journey-finish"><img :src="careMascot" alt="" /><span>{{ language === 'en' ? 'A clear next step, every day.' : 'နေ့တိုင်း ရှင်းလင်းသော နောက်တစ်ဆင့်။' }}</span></div>
          </div>
        </section>

        <section id="services" class="content-section services-section reveal-on-scroll">
          <div class="section-heading split-heading"><div><p class="eyebrow">02 / Skino services</p><h2>{{ t.serviceTitle }}</h2></div><p>{{ t.serviceText }}</p></div>
          <div class="service-grid"><article v-for="(module, index) in modules" :key="module.title" class="service-card" :class="{ featured: index === 0 }" :style="{ '--tone': module.tone }"><div class="service-card-top"><span class="service-icon"><img :src="module.icon" alt="" /></span><span class="service-status">{{ module.status }}</span></div><div class="service-copy"><small>{{ module.feature }}</small><h3>{{ module.title }}</h3><p>{{ module.subtitle }}</p></div><button type="button" @click="openLogin">{{ language === 'en' ? 'Open this service' : 'ဝန်ဆောင်မှု ဖွင့်မယ်' }} <span>↗</span></button></article></div>
          <div class="service-promise"><div><span>✓</span><p><strong>{{ language === 'en' ? 'One connected journey' : 'ချိတ်ဆက်ထားသော ခရီးစဉ်တစ်ခု' }}</strong><small>{{ language === 'en' ? 'Your result moves with you from scan to routine and history.' : 'သင့်ရလဒ်သည် စကင်မှ နေ့စဉ်အစီအစဉ်နှင့် မှတ်တမ်းအထိ အတူလိုက်ပါသည်။' }}</small></p></div><div><span>✓</span><p><strong>{{ language === 'en' ? 'Private by design' : 'ကိုယ်ရေးလုံခြုံမှု ဦးစားပေး' }}</strong><small>{{ language === 'en' ? 'Consent is clear, and AI improvement remains your choice.' : 'သဘောတူညီချက်ကို ရှင်းပြပြီး AI တိုးတက်မှုတွင် ပါဝင်ခြင်းကို သင်ရွေးချယ်နိုင်သည်။' }}</small></p></div></div>
        </section>

        <section class="trust-demo-section reveal-on-scroll" aria-labelledby="trust-demo-title"><div><p class="eyebrow">Trust / Demo transparency</p><h2 id="trust-demo-title">Clear guidance, clear limits.</h2><p>Camera alignment runs inside your browser. Your photo is sent only when you choose Analyze. Model-learning is optional, and Skino provides wellness guidance—not a medical diagnosis.</p></div><div class="trust-demo-points"><span><b>Browser guidance</b><small>Face position and capture quality are checked before upload.</small></span><span><b>Your choice</b><small>AI-improvement consent can be changed from your profile.</small></span><span><b>Safety first</b><small>Urgent, painful, or rapidly changing concerns need professional care.</small></span></div></section>

        <section id="pricing" class="content-section reveal-on-scroll">
          <div class="section-heading split-heading"><div><p class="eyebrow">03 / Fair and flexible</p><h2>Choose care that fits your pace.</h2></div><p>Start free, add a scan only when you need one, or choose ongoing tracking. Final checkout details will always be shown before payment.</p></div>
          <PricingPlans @choose="choosePublicPlan" />
          <div class="mt-4 flex flex-col items-start justify-between gap-3 rounded-2xl border border-skino-line bg-white px-5 py-4 sm:flex-row sm:items-center"><p class="mb-0 text-xs leading-5 text-skino-muted"><strong class="text-skino-ink">Our goal:</strong> make useful skin guidance accessible while keeping your choices clear.</p><span class="rounded-full bg-emerald-50 px-3 py-1.5 text-[10px] text-skino-green">No hidden plan changes</span></div>
        </section>

        <section id="about" class="content-section about-section reveal-on-scroll"><div class="about-visual"><img :src="waveMascot" alt="Skino waving" /><span>Guidance<br />with care</span></div><div><p class="eyebrow">04 / About Skino</p><h2>{{ t.aboutTitle }}</h2><p>{{ t.aboutText }}</p><div class="about-values"><span>Consent first</span><span>Easy to understand</span><span>Professional handoff</span></div></div></section>
        <section id="contact" class="cta-section reveal-on-scroll"><img class="cta-care-mascot" :src="careMascot" alt="Skino care buddy" /><div><p class="eyebrow">Contact us / Start with consent</p><h2>{{ t.ctaTitle }}</h2><p>{{ t.ctaText }} Need help? Team Kairo is ready to guide you.</p></div><button class="primary-button" type="button" @click="openLogin">{{ t.startScan }} <span>→</span></button></section>
      </main>

      <main v-else-if="activeView === 'terms' || activeView === 'privacy'" class="public-main legal-page"><button class="back-link" type="button" @click="scrollTo('home')">← Back to Skino</button><article v-if="activeView === 'terms'"><p class="eyebrow">Effective August 20, 2026</p><h1>Skino Terms of Service</h1><p>Skino is a wellness and skincare guidance demo. It does not diagnose, treat, or replace advice from a qualified medical professional.</p><h2>Using Skino</h2><p>You must provide accurate account information and use face-scan features only for yourself or with the photographed person’s permission. Do not use Skino for emergencies.</p><h2>Your results</h2><p>Results depend on image quality, lighting, camera hardware, and the current AI model. They may be incomplete or incorrect. Retake low-quality scans and seek professional help for painful, severe, or rapidly changing concerns.</p><h2>Demo pricing</h2><p>Pricing plans shown in this version are previews. No payment or subscription is created by selecting a plan.</p><h2>Your control</h2><p>You can review or delete saved scans, change optional model-learning consent, and stop an active routine from your workspace.</p></article><article v-else><p class="eyebrow">Effective August 20, 2026</p><h1>Skino Privacy Policy</h1><p>Skino processes account information, optional profile details, face photographs, scan results, and routine activity to provide the features you request.</p><h2>Face-scan processing</h2><p>Camera alignment guidance runs in your browser. When you choose Analyze, the selected photograph and capture-quality metadata are sent to the Skino service for analysis and, when signed in, history storage.</p><h2>Optional AI improvement</h2><p>Your scan is not placed in the model-improvement review queue unless you explicitly enable that choice. You can turn it off later. Submitted samples still require human review before any training use.</p><h2>Storage and deletion</h2><p>Signed-in scans remain connected to your account until you delete them or the service applies its retention policy. Deleting a scan is permanent and may require stopping a routine that uses it.</p><h2>Contact</h2><p>For this hackathon demo, contact Team Kairo through the project team to request account or data review.</p></article></main>

      <main v-else class="grid min-h-[calc(100vh-88px)] place-items-center bg-[radial-gradient(circle_at_top,rgba(243,106,22,.13),transparent_34%)] bg-skino-cream px-4 py-7 text-skino-ink sm:py-10">
        <form class="grid w-full max-w-[410px] gap-4 rounded-[26px] border border-skino-line bg-white p-6 shadow-skino sm:p-8" @submit.prevent="enterDashboard">
          <div class="grid place-items-center text-center">
            <img class="size-14 rounded-2xl border border-skino-line-orange object-cover shadow-skino-sm" :src="logo" alt="" />
            <p class="mb-0 mt-3 text-[10px] font-medium uppercase tracking-[.14em] text-skino-orange-dark">Private skin workspace</p>
            <h1 class="mt-2 text-3xl font-medium leading-none tracking-[-.045em]">{{ t.loginTitle }}</h1>
            <p class="mb-0 mt-2 max-w-xs text-xs leading-5 text-skino-muted">{{ t.loginText }}</p>
          </div>
          <div v-if="authLoading" class="auth-progress-line" role="status" aria-live="polite"><i></i><span>Securely connecting to your workspace…</span></div>
          <div v-if="googleClientId" ref="googleButton" class="grid min-h-11 place-items-center overflow-hidden"></div>
          <div v-else class="grid gap-2 rounded-xl border border-amber-200 bg-amber-50 p-3 text-center"><p class="mb-0 text-[11px] leading-4 text-amber-900">Google sign-in is temporarily unavailable. Please continue securely with email.</p></div>
          <div class="flex items-center gap-3 text-[9px] uppercase tracking-[.06em] text-skino-muted before:h-px before:flex-1 before:bg-skino-line after:h-px after:flex-1 after:bg-skino-line"><span>or continue with email</span></div>
          <p v-if="authError" class="mb-0 rounded-xl border border-red-200 bg-red-50 p-3 text-[11px] leading-4 text-red-700">{{ authError }}</p>
          <label class="grid gap-2 text-[11px] text-skino-muted">{{ t.email }}<input v-model="loginForm.email" class="h-11 w-full rounded-xl border border-skino-line bg-skino-paper px-3 text-sm text-skino-ink outline-none transition focus:border-skino-orange focus:bg-white focus:ring-4 focus:ring-orange-100" type="email" autocomplete="email" required /></label>
          <label class="grid gap-2 text-[11px] text-skino-muted">{{ t.password }}<span class="relative block"><input v-model="loginForm.password" class="h-11 w-full rounded-xl border border-skino-line bg-skino-paper px-3 pr-16 text-sm text-skino-ink outline-none transition focus:border-skino-orange focus:bg-white focus:ring-4 focus:ring-orange-100" :type="showPassword ? 'text' : 'password'" autocomplete="current-password" required /><button class="absolute right-2 top-1.5 min-h-8 rounded-lg px-2 text-[10px] text-skino-orange-dark hover:bg-skino-orange-soft" type="button" @click="showPassword = !showPassword">{{ showPassword ? 'Hide' : 'Show' }}</button></span></label>
          <div class="flex items-center justify-between gap-3"><label class="flex items-center gap-2 text-[10px] text-skino-muted"><input v-model="loginForm.remember" class="size-4 accent-skino-orange" type="checkbox" />{{ t.remember }}</label><button class="text-[10px] text-skino-orange-dark hover:underline" type="button">{{ t.forgot }}</button></div>
          <button class="inline-flex min-h-11 w-full items-center justify-center gap-2 rounded-xl bg-skino-orange px-5 text-xs font-medium text-white shadow-skino-sm transition hover:-translate-y-0.5 hover:bg-skino-orange-dark disabled:cursor-not-allowed disabled:opacity-50" type="submit" :disabled="authLoading"><i v-if="authLoading" class="button-spinner light"></i>{{ authLoading ? 'Connecting…' : t.loginButton }} <span v-if="!authLoading">→</span></button>
          <p class="mb-0 text-center text-[9px] text-skino-muted"><span class="text-skino-green">✓</span> Secure connection to your Skino account</p>
        </form>
      </main>

      <footer v-if="activeView !== 'login'" class="site-footer">
        <div class="footer-main"><div class="footer-intro"><div class="footer-brand"><img :src="logo" alt="" /><span>Skino<small>Your AI Skin Care Buddy</small></span></div><p>Simple skin guidance from your first scan to the habits you can keep.</p><button type="button" @click="openLogin">Start your private scan <span>→</span></button></div><div class="footer-column"><strong>Explore</strong><button type="button" @click="scrollTo('home')">Home</button><button type="button" @click="scrollTo('how')">How it works</button><button type="button" @click="scrollTo('services')">Services</button><button type="button" @click="scrollTo('pricing')">Pricing</button></div><div class="footer-column"><strong>Skino</strong><button type="button" @click="scrollTo('about')">About us</button><button type="button" @click="scrollTo('contact')">Contact us</button><button type="button" @click="openLogin">Sign in</button></div><div class="footer-column"><strong>Safety</strong><span>Guidance, not diagnosis</span><span>Consent before scan</span><span>AI training is optional</span></div></div>
        <div class="footer-bottom"><span>© 2026 Team Kairo. Built with care.</span><span class="flex gap-4"><button type="button" @click="openLegal('terms')">Terms</button><button type="button" @click="openLegal('privacy')">Privacy</button></span><span>Scan · Understand · Care</span></div>
      </footer>
      <div v-if="activeView !== 'login' && showStickyActions" class="sticky-actions"><button class="primary-button" type="button" @click="openLogin">{{ t.startScan }} <span>→</span></button></div>
    </template>

    <main v-else-if="!onboardingComplete" class="onboarding-page text-skino-ink">
      <header class="onboarding-topbar">
        <div class="flex min-w-0 items-center gap-3"><img class="size-11 shrink-0 rounded-2xl border border-skino-line-orange object-cover shadow-skino-sm" :src="logo" alt="Skino" /><div class="grid min-w-0"><span class="text-sm font-medium">Skino</span><small class="truncate text-[11px] text-skino-muted">Private skin workspace · ကိုယ်ပိုင် Skin Workspace</small></div></div>
        <div class="flex shrink-0 items-center gap-3"><span class="hidden items-center gap-1.5 rounded-full bg-emerald-50 px-3 py-1.5 text-[11px] text-skino-green sm:flex"><i class="size-1.5 rounded-full bg-emerald-500"></i>Consent first</span><button class="min-h-10 rounded-full border border-skino-line bg-white px-3 text-[11px] text-skino-muted transition hover:border-skino-orange hover:text-skino-orange-dark" type="button" @click="signOut">{{ t.logout }}</button></div>
      </header>

      <section class="onboarding-panel">
        <div class="onboarding-progress" aria-label="Onboarding progress">
          <span v-for="(page, index) in onboardingPages" :key="page.title" :class="{ active: index === onboardingStep, complete: index < onboardingStep }"><i>{{ index < onboardingStep ? '✓' : index + 1 }}</i><b>{{ index === 0 ? 'Welcome' : index === 1 ? 'Safe scan' : 'Consent' }}</b><small>{{ index === 0 ? 'မိတ်ဆက်' : index === 1 ? 'စကင်လမ်းညွှန်' : 'ခွင့်ပြုချက်' }}</small></span>
        </div>

        <div class="onboarding-hero-grid">
          <div class="onboarding-message">
            <p class="onboarding-kicker">{{ currentOnboarding.kicker }}</p>
            <h1>{{ currentOnboarding.title }}</h1>
            <h2>{{ currentOnboarding.titleMy }}</h2>
            <p>{{ currentOnboarding.body }}</p>
            <p class="onboarding-myanmar-copy">{{ currentOnboarding.bodyMy }}</p>
            <div v-if="isLastOnboardingStep" class="onboarding-data-summary">
              <span><i>01</i><b>What is used</b><small>ရွေးထားသော မျက်နှာပုံ၊ scan result နှင့် routine activity</small></span>
              <span><i>02</i><b>Why it is used</b><small>Analysis၊ ရလဒ်ပြသမှုနှင့် ကိုယ်ပိုင် care guidance</small></span>
              <span><i>03</i><b>Your control</b><small>AI လေ့လာရေးသည် optional ဖြစ်ပြီး Profile မှ ပြောင်းနိုင်သည်</small></span>
            </div>
            <p v-if="onboardingError" class="onboarding-error" role="alert">{{ onboardingError }}</p>
          </div>

          <div class="onboarding-art" :class="{ 'consent-art': isLastOnboardingStep }">
            <span>Step {{ onboardingStep + 1 }} / {{ onboardingPages.length }}</span>
            <i aria-hidden="true"></i>
            <img :src="currentOnboarding.image" alt="" />
            <small>{{ isLastOnboardingStep ? 'Nothing is shared for model learning unless you choose it.' : 'Guided · Clear · Private' }}</small>
          </div>
        </div>

        <div v-if="isLastOnboardingStep" class="onboarding-consent-area">
          <div class="onboarding-consent-heading"><div><p>Choose before your first scan</p><h2>လိုအပ်သော ခွင့်ပြုချက် ၂ ခုကို ဖတ်ပြီး ရွေးပါ</h2></div><span><b>{{ Number(acceptedTerms) + Number(acceptedScanConsent) }}/2</b> required selected</span></div>
          <div class="onboarding-consent-grid">
            <label v-for="consent in onboardingConsents" :key="consent.key" class="onboarding-consent-card" :class="[(consent.key === 'terms' ? acceptedTerms : consent.key === 'scan' ? acceptedScanConsent : allowModelTraining) ? 'selected' : '', consent.key === 'training' ? 'optional' : '']">
              <span class="consent-icon"><img :src="consent.icon" alt="" /></span>
              <span class="consent-copy"><small>{{ consent.badge }}</small><strong>{{ consent.titleMy }}</strong><b>{{ consent.title }}</b><span>{{ consent.textMy }}</span><em>{{ consent.text }}</em><span v-if="consent.key === 'terms'" class="consent-links"><a href="/terms.html" target="_blank" rel="noopener" @click.stop>Terms</a><a href="/privacy.html" target="_blank" rel="noopener" @click.stop>Privacy Policy</a></span></span>
              <input v-if="consent.key === 'terms'" v-model="acceptedTerms" type="checkbox" />
              <input v-else-if="consent.key === 'scan'" v-model="acceptedScanConsent" type="checkbox" />
              <input v-else v-model="allowModelTraining" type="checkbox" />
            </label>
          </div>
        </div>

        <footer class="onboarding-actions">
          <p><span>✓</span> Required choices are saved securely to your account. Optional AI improvement can be changed later.</p>
          <div><button v-if="onboardingStep > 0" class="onboarding-back" type="button" @click="previousOnboardingStep">← Back</button><button class="onboarding-next" type="button" :disabled="authLoading || (isLastOnboardingStep && !canFinishOnboarding)" @click="nextOnboardingStep"><i v-if="authLoading" class="button-spinner light"></i>{{ authLoading ? 'Saving your choices…' : (isLastOnboardingStep ? 'သဘောတူပြီး Workspace ဝင်မယ်' : 'Continue') }} <span v-if="!authLoading">→</span></button></div>
        </footer>
      </section>
    </main>

    <UserWorkspace v-else :session="session" :allow-model-training="allowModelTraining" @logout="signOut" @profile-updated="updateSessionProfile" @training-consent-updated="updateTrainingChoice" />
  </div>
</template>
