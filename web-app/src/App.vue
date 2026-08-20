<script setup>
import { computed, ref } from 'vue'
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

const heroFeature = {
  label: 'Live Face Scan',
  code: 'Scan / #0042',
  title: 'Skin story detected',
  score: '82',
  tags: ['Clear light', 'Face ready', 'Routine match'],
  note: 'Hold still. Skino is reading visible skin patterns.',
}

const modules = [
  {
    title: 'AI Skin Scan',
    subtitle: 'Upload or capture a face image and review visible skin guidance.',
    icon: scanIcon,
    tone: '#ff6a00',
    status: 'Ready',
  },
  {
    title: 'Routine',
    subtitle: 'Morning and night beauty steps based on the latest scan.',
    icon: routineIcon,
    tone: '#22b573',
    status: 'Daily',
  },
  {
    title: 'Specialist',
    subtitle: 'Find specialist support when a case needs closer review.',
    icon: specialistIcon,
    tone: '#7d5cff',
    status: 'Care',
  },
  {
    title: 'Appointment',
    subtitle: 'Request a consultation and track the current status.',
    icon: reportIcon,
    tone: '#ff9a3d',
    status: 'Request',
  },
  {
    title: 'History',
    subtitle: 'Review previous scans, scores, and concern changes.',
    icon: historyIcon,
    tone: '#7d5cff',
    status: 'Timeline',
  },
  {
    title: 'Progress',
    subtitle: 'See how your skin journey changes across check-ins.',
    icon: progressIcon,
    tone: '#22b573',
    status: 'Track',
  },
]

const safetyCards = [
  {
    number: '01',
    title: 'Guidance, not diagnosis',
    text: 'Skino explains visible patterns for beauty care and never replaces medical advice.',
  },
  {
    number: '02',
    title: 'Consent first',
    text: 'Face scans are sensitive, so the user must understand what is being processed.',
  },
  {
    number: '03',
    title: 'Specialist handoff',
    text: 'When a concern looks uncertain or serious, the product path moves toward care support.',
  },
  {
    number: '04',
    title: 'History with control',
    text: 'Progress tracking should help users compare changes without hiding privacy choices.',
  },
]

const analysisBars = [
  { label: 'Skin balance', value: 82, tone: '#ff6a00' },
  { label: 'Routine match', value: 76, tone: '#22b573' },
  { label: 'Scan clarity', value: 92, tone: '#7d5cff' },
  { label: 'Progress signal', value: 68, tone: '#ff9a3d' },
]

const routineSteps = [
  'Gentle cleanser',
  'Hydrating care',
  'Light moisturizer',
  'Daily sunscreen',
]

const memoryStats = [
  { value: '+18%', label: 'Routine consistency' },
  { value: '12', label: 'Day streak' },
  { value: '06', label: 'Weekly check-ins' },
  { value: '82', label: 'Latest score' },
]

const teamMembers = [
  { name: 'Tun Aung Lwin', role: 'Project lead' },
  { name: 'Sai Bhone Myat', role: 'Frontend and product UI' },
  { name: 'Mn', role: 'Backend and data flow' },
  { name: 'Lei War Khaing', role: 'AI and product research' },
]

const currentTitle = computed(() => (isLoggedIn.value ? 'User Dashboard' : 'Skino'))

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
            <p class="eyebrow">Skino / Personal Skin Intelligence</p>
            <h1>
              <span>Your skin</span>
              <span>has a story.</span>
              <span class="orange-line">Skino listens.</span>
            </h1>
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
            <div class="phone-preview">
              <div class="phone-topline">
                <span>{{ heroFeature.label }}</span>
                <strong>{{ heroFeature.score }}</strong>
              </div>
              <div class="slide-code">{{ heroFeature.code }}</div>
              <div class="hero-image-stage">
                <img class="hero-mascot" :src="heroMascot" alt="" />
                <span class="scan-sweep"></span>
              </div>
              <div class="quality-meter">
                <span>{{ heroFeature.title }}</span>
                <strong>Active</strong>
              </div>
              <div class="scan-summary">
                <span v-for="tag in heroFeature.tags" :key="tag">{{ tag }}</span>
              </div>
            </div>

            <div class="floating-note">
              <img :src="careMascot" alt="" />
              <div>
                <span>Skino Buddy</span>
                <strong>{{ heroFeature.note }}</strong>
              </div>
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
              <h2 id="services-title">Face scan, routine, care, and progress in one path</h2>
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

        <section class="landing-section product-story" aria-labelledby="story-title">
          <div class="section-heading">
            <p class="eyebrow">Skin AI / 004</p>
            <h2 id="story-title">Understand what you see, then know what to do next</h2>
          </div>

          <div class="story-grid">
            <article class="score-panel">
              <p class="eyebrow">Analysis preview</p>
              <strong>82</strong>
              <span>Skin score</span>
              <small>Demo result from the customer dashboard flow</small>
            </article>

            <article class="bars-panel">
              <div v-for="bar in analysisBars" :key="bar.label" class="bar-row" :style="{ '--bar-tone': bar.tone }">
                <div>
                  <span>{{ bar.label }}</span>
                  <strong>{{ bar.value }}%</strong>
                </div>
                <i><b :style="{ width: `${bar.value}%` }"></b></i>
              </div>
            </article>

            <article class="noticed-panel">
              <img :src="reportIcon" alt="" />
              <h3>What Skino noticed</h3>
              <p>
                The product should translate scan results into simple care language:
                visible skin type, concern level, routine reason, and when to ask a specialist.
              </p>
            </article>
          </div>
        </section>

        <section class="landing-section routine-band" aria-labelledby="routine-title">
          <div>
            <p class="eyebrow">Routine / Daily care</p>
            <h2 id="routine-title">Your skin. Your products. Your routine.</h2>
            <p>
              This is the direction for the logged-in dashboard: clear steps, friendly reminders,
              and progress tracking instead of random product guessing.
            </p>
          </div>

          <div class="routine-timeline">
            <span v-for="(step, index) in routineSteps" :key="step">
              <i>{{ String(index + 1).padStart(2, '0') }}</i>
              <strong>{{ step }}</strong>
            </span>
          </div>
        </section>

        <section class="landing-section memory-section" aria-labelledby="memory-title">
          <div class="section-heading section-heading-row">
            <div>
              <p class="eyebrow">Progress / Skin memory</p>
              <h2 id="memory-title">See how far your care journey has moved</h2>
            </div>
            <img class="section-mascot" :src="progressIcon" alt="" />
          </div>

          <div class="memory-grid">
            <article v-for="stat in memoryStats" :key="stat.label" class="memory-card">
              <strong>{{ stat.value }}</strong>
              <span>{{ stat.label }}</span>
            </article>
          </div>
        </section>

        <section class="landing-section safety-section" aria-labelledby="safety-title">
          <div class="section-heading">
            <p class="eyebrow">Safety / Responsible AI</p>
            <h2 id="safety-title">Smart AI with clear limits</h2>
          </div>

          <div class="safety-grid">
            <article v-for="card in safetyCards" :key="card.title" class="safety-card">
              <span>{{ card.number }}</span>
              <h3>{{ card.title }}</h3>
              <p>{{ card.text }}</p>
            </article>
          </div>
        </section>

        <section id="about" class="landing-section about-band" aria-labelledby="about-title">
          <div>
            <p class="eyebrow">About us</p>
            <h2 id="about-title">Team Kairo builds Skino for clear skin-care guidance</h2>
            <p>
              Skino is a wellness and skincare assistant, not a medical diagnosis system.
              The web app path keeps Laravel as the business API, Python as the AI service,
              and Vue.js as the customer experience.
            </p>
          </div>
          <div class="team-grid" aria-label="Team Kairo members">
            <article v-for="member in teamMembers" :key="member.name" class="team-card">
              <span>{{ member.name.slice(0, 1) }}</span>
              <strong>{{ member.name }}</strong>
              <small>{{ member.role }}</small>
            </article>
          </div>
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

    <footer v-if="!isLoggedIn && activeView !== 'login'" id="contact" class="site-footer">
      <div>
        <span class="brand-mark footer-mark">
          <img :src="logo" alt="" />
        </span>
        <p class="eyebrow">Contact / Team Kairo</p>
        <h2>Start understanding your skin with Skino.</h2>
      </div>
      <div class="footer-contact">
        <strong>Skino — Your AI Skin Care Buddy</strong>
        <p>Vue frontend, Laravel API, and Python AI service built for a complete skincare demo path.</p>
        <button class="primary-button" type="button" @click="openView('login')">Open Login</button>
      </div>
    </footer>
  </div>
</template>
