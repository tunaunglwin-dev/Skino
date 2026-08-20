<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import logo from './assets/branding/skino_logo.png'
import heroMascot from './assets/branding/skino_little_guy_wave.png'
import scanIcon from './assets/branding/skino_icon_scan.png'
import routineIcon from './assets/branding/skino_icon_routine.png'
import specialistIcon from './assets/branding/skino_icon_specialist.png'
import historyIcon from './assets/branding/skino_icon_history.png'
import progressIcon from './assets/branding/skino_icon_progress.png'
import reportIcon from './assets/branding/skino_icon_report.png'
import careMascot from './assets/branding/skino_little_guy_care.png'

const activeView = ref('home')
const isLoggedIn = ref(false)
const currentHeroSlide = ref(0)
let heroTimer

const publicNavItems = [
  { label: 'Home', view: 'home', target: 'home' },
  { label: 'Services', view: 'services', target: 'services' },
  { label: 'About us', view: 'about', target: 'about' },
  { label: 'Contact', view: 'contact', target: 'contact' },
  { label: 'Login', view: 'login' },
]

const howSteps = [
  {
    title: 'Scan',
    text: 'Upload or capture a clear face image for visible skin guidance.',
    icon: scanIcon,
  },
  {
    title: 'Understand',
    text: 'Review skin type, concerns, score, and simple routine advice.',
    icon: reportIcon,
  },
  {
    title: 'Improve',
    text: 'Follow daily care, track progress, and request specialist help.',
    icon: routineIcon,
  },
]

const heroSlides = [
  {
    label: 'Live Face Scan',
    code: 'Scan / #0042',
    title: 'Skin story detected',
    score: '82',
    mascot: heroMascot,
    tags: ['Clear light', 'Face ready', 'Routine match'],
    note: 'Hold still. Skino is reading visible skin patterns.',
  },
  {
    label: 'Routine Engine',
    code: 'Care / AM',
    title: 'Daily care built',
    score: '04',
    mascot: careMascot,
    tags: ['Cleanser', 'Moisturizer', 'SPF'],
    note: 'A simple routine is prepared from the latest scan.',
  },
  {
    label: 'Progress Memory',
    code: 'Week / 06',
    title: 'Progress tracked',
    score: '+18',
    mascot: progressIcon,
    tags: ['History', 'Check-ins', 'Consistency'],
    note: 'Skino keeps the journey clear without making medical claims.',
  },
]

const modules = [
  {
    title: 'AI Skin Scan',
    subtitle: 'Upload or capture a face image and review visible skin guidance.',
    icon: scanIcon,
    tone: '#f98128',
    status: 'Ready',
  },
  {
    title: 'Routine',
    subtitle: 'Morning and night beauty steps based on the latest scan.',
    icon: routineIcon,
    tone: '#0e5c56',
    status: 'Daily',
  },
  {
    title: 'Specialist',
    subtitle: 'Find specialist support when a case needs closer review.',
    icon: specialistIcon,
    tone: '#9e6a36',
    status: 'Care',
  },
  {
    title: 'Appointment',
    subtitle: 'Request a consultation and track the current status.',
    icon: reportIcon,
    tone: '#805d93',
    status: 'Request',
  },
  {
    title: 'History',
    subtitle: 'Review previous scans, scores, and concern changes.',
    icon: historyIcon,
    tone: '#376c8f',
    status: 'Timeline',
  },
  {
    title: 'Progress',
    subtitle: 'See how your skin journey changes across check-ins.',
    icon: progressIcon,
    tone: '#c35d4f',
    status: 'Track',
  },
]

const currentTitle = computed(() => (isLoggedIn.value ? 'User Dashboard' : 'Skino'))
const heroSlide = computed(() => heroSlides[currentHeroSlide.value])

function openView(view) {
  activeView.value = view
  if (view === 'login') {
    return
  }

  const target = publicNavItems.find((item) => item.view === view)?.target
  window.setTimeout(() => {
    const section = target ? document.getElementById(target) : null
    if (section) {
      section.scrollIntoView({ behavior: 'smooth', block: 'start' })
      return
    }

    window.scrollTo({ top: 0, behavior: 'smooth' })
  }, 0)
}

function enterDashboard() {
  isLoggedIn.value = true
  activeView.value = 'dashboard'
}

function signOut() {
  isLoggedIn.value = false
  activeView.value = 'home'
}

function chooseHeroSlide(index) {
  currentHeroSlide.value = index
}

onMounted(() => {
  heroTimer = window.setInterval(() => {
    currentHeroSlide.value = (currentHeroSlide.value + 1) % heroSlides.length
  }, 3600)
})

onBeforeUnmount(() => {
  window.clearInterval(heroTimer)
})
</script>

<template>
  <div class="app-shell">
    <header class="site-header">
      <button class="brand-button" type="button" @click="openView(isLoggedIn ? 'dashboard' : 'home')">
        <span class="brand-mark">
          <img :src="logo" alt="" />
        </span>
        <span>
          <strong>{{ currentTitle }}</strong>
          <small>AI beauty care</small>
        </span>
      </button>

      <nav class="nav-links" aria-label="Primary navigation">
        <button
          v-for="item in publicNavItems"
          :key="item.view"
          type="button"
          :class="{ active: activeView === item.view, 'login-nav-item': item.view === 'login' }"
          @click="openView(item.view)"
        >
          {{ item.label }}
        </button>
      </nav>

      <div v-if="isLoggedIn" class="header-actions">
        <button v-if="isLoggedIn" class="ghost-button" type="button" @click="signOut">Logout</button>
      </div>
    </header>

    <main>
      <template v-if="!isLoggedIn && activeView !== 'login'">
        <section id="home" class="landing-hero">
          <div class="home-copy">
            <p class="eyebrow">AI beauty care platform</p>
            <h1>Skino</h1>
            <p>
              Scan your skin, understand visible concerns, follow a simple beauty routine,
              and request specialist support when your care journey needs a closer look.
            </p>
            <div class="hero-actions">
              <button class="primary-button" type="button" @click="openView('login')">Start Skin Scan</button>
              <button class="ghost-button" type="button" @click="openView('services')">Explore Services</button>
            </div>
            <div class="hero-stat-strip" aria-label="Skino platform highlights">
              <span>Guest scan</span>
              <span>Routine guidance</span>
              <span>Progress history</span>
            </div>
          </div>

          <div class="hero-showcase" aria-label="Skino product preview">
            <div class="phone-preview" :key="heroSlide.title">
              <div class="phone-topline">
                <span>{{ heroSlide.label }}</span>
                <strong>{{ heroSlide.score }}</strong>
              </div>
              <div class="slide-code">{{ heroSlide.code }}</div>
              <img class="hero-mascot" :src="heroSlide.mascot" alt="" />
              <div class="quality-meter">
                <span>{{ heroSlide.title }}</span>
                <strong>Active</strong>
              </div>
              <div class="scan-summary">
                <span v-for="tag in heroSlide.tags" :key="tag">{{ tag }}</span>
              </div>
            </div>

            <div class="floating-note">
              <img :src="careMascot" alt="" />
              <div>
                <span>Skino Buddy</span>
                <strong>{{ heroSlide.note }}</strong>
              </div>
            </div>

            <div class="hero-pager" aria-label="Hero preview slides">
              <button
                v-for="(slide, index) in heroSlides"
                :key="slide.title"
                type="button"
                :class="{ active: currentHeroSlide === index }"
                @click="chooseHeroSlide(index)"
              >
                <span>{{ index + 1 }}</span>
              </button>
            </div>
          </div>
        </section>

        <section class="landing-section how-section" aria-labelledby="how-title">
          <div class="section-heading">
            <p class="eyebrow">How it works</p>
            <h2 id="how-title">From scan to daily care in three simple steps</h2>
          </div>
          <div class="step-grid">
            <article v-for="(step, index) in howSteps" :key="step.title" class="step-card">
              <span class="step-number">{{ index + 1 }}</span>
              <img :src="step.icon" alt="" />
              <h3>{{ step.title }}</h3>
              <p>{{ step.text }}</p>
            </article>
          </div>
        </section>

        <section id="services" class="landing-section" aria-labelledby="services-title">
          <div class="section-heading section-heading-row">
            <div>
              <p class="eyebrow">Services</p>
              <h2 id="services-title">Everything the user dashboard will grow into</h2>
            </div>
            <button class="ghost-button" type="button" @click="openView('login')">Preview Dashboard</button>
          </div>
          <div class="service-grid">
            <article
              v-for="module in modules.slice(0, 4)"
              :key="module.title"
              class="service-card"
              :style="{ '--module-tone': module.tone }"
            >
              <img :src="module.icon" alt="" />
              <span>{{ module.status }}</span>
              <h3>{{ module.title }}</h3>
              <p>{{ module.subtitle }}</p>
            </article>
          </div>
        </section>

        <section id="about" class="landing-section about-band" aria-labelledby="about-title">
          <div>
            <p class="eyebrow">About us</p>
            <h2 id="about-title">Built for beauty guidance, privacy, and steady progress</h2>
            <p>
              Skino is a wellness and skincare assistant, not a medical diagnosis system.
              The web app path keeps Laravel as the business API, Python as the AI service,
              and Vue.js as the customer experience.
            </p>
          </div>
          <div class="privacy-card">
            <strong>Your scan stays sensitive</strong>
            <p>Face images should be handled with consent, clear purpose, and careful storage rules.</p>
          </div>
        </section>

        <section id="contact" class="landing-section contact-panel" aria-labelledby="contact-title">
          <div>
            <p class="eyebrow">Contact</p>
            <h2 id="contact-title">Ready for the next UI step</h2>
            <p>Next we can connect each card to real pages: scan, routine, appointment, history, and profile.</p>
          </div>
          <button class="primary-button" type="button" @click="openView('login')">Open Login</button>
        </section>
      </template>

      <section v-else-if="!isLoggedIn && activeView === 'login'" class="login-layout">
        <div class="login-copy">
          <p class="eyebrow">User access</p>
          <h1>Welcome back to Skino</h1>
          <p>Continue into your skin care workspace. This preview uses the final visual direction before API auth is connected.</p>
          <div class="login-benefits">
            <span>Private skin scan flow</span>
            <span>Routine and appointment modules</span>
            <span>Mobile-first Vue dashboard</span>
          </div>
        </div>

        <form class="login-card" @submit.prevent="enterDashboard">
          <div class="form-heading">
            <span class="brand-mark">
              <img :src="logo" alt="" />
            </span>
            <div>
              <h2>Login</h2>
              <p>Preview the customer dashboard</p>
            </div>
          </div>
          <label>
            Email
            <input type="email" value="demo@skino.local" autocomplete="email" />
          </label>
          <label>
            Password
            <input type="password" value="password" autocomplete="current-password" />
          </label>
          <button class="primary-button full-width" type="submit">Go To Dashboard</button>
        </form>
      </section>

      <section v-else class="dashboard-layout">
        <div class="dashboard-hero">
          <div>
            <p class="eyebrow">User dashboard</p>
            <h1>Your Skino workspace</h1>
            <p>
              Mobile-responsive module cards for the customer flow. Backend actions are intentionally
              not connected yet.
            </p>
          </div>
          <div class="health-card">
            <span>Skin score</span>
            <strong>82</strong>
            <small>Demo preview</small>
          </div>
        </div>

        <div class="module-grid">
          <button
            v-for="module in modules"
            :key="module.title"
            class="module-card"
            type="button"
            :style="{ '--module-tone': module.tone }"
          >
            <span class="module-status">{{ module.status }}</span>
            <span class="module-icon">
              <img :src="module.icon" alt="" />
            </span>
            <span class="module-title">{{ module.title }}</span>
            <span class="module-subtitle">{{ module.subtitle }}</span>
          </button>
        </div>
      </section>
    </main>
  </div>
</template>
