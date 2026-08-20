<script setup>
import { computed, onMounted, onUnmounted, ref } from 'vue'
import logo from './assets/branding/skino_logo.png'
import scanIcon from './assets/branding/skino_icon_scan.png'
import routineIcon from './assets/branding/skino_icon_routine.png'
import specialistIcon from './assets/branding/skino_icon_specialist.png'
import historyIcon from './assets/branding/skino_icon_history.png'
import progressIcon from './assets/branding/skino_icon_progress.png'
import reportIcon from './assets/branding/skino_icon_report.png'

const activeView = ref('home')
const isLoggedIn = ref(false)
const language = ref('en')
const showStickyActions = ref(false)

const copy = {
  en: {
    home: 'Home',
    services: 'Services',
    about: 'About us',
    contact: 'Contact',
    login: 'Login',
    logout: 'Logout',
    brandNote: 'AI beauty care',
    eyebrow: 'Skino / Personal Skin Intelligence',
    heroTitle: ['Your skin', 'has a story.', 'Skino listens.'],
    heroBody:
      'Try a face beauty scan first. Understand visible concerns, get gentle routine guidance, and save progress when you are ready.',
    startScan: 'Start scan',
    exploreServices: 'Services',
    howItWorks: 'How it works',
    heroChips: ['Guest scan', 'No long setup', 'Routine ready'],
    quickTitle: 'Ready for your first scan',
    quickText: 'Scan with the acne model, get focused concerns, then move into daily care and progress tracking.',
    actionCards: [
      ['Face beauty scan', 'Check acne severity and skin score in under a minute.'],
      ['Daily improvement', 'Gentle routines, reminders, and next scan check-ins.'],
      ['Specialist help', 'Recommended when acne looks moderate, severe, or uncertain.'],
    ],
    howTitle: 'From scan to daily care in three simple steps',
    howSteps: [
      ['Scan', 'Upload or capture a clear face image for visible skin guidance.'],
      ['Understand', 'Review skin type, concerns, score, and simple routine advice.'],
      ['Improve', 'Follow daily care, track progress, and request specialist help.'],
    ],
    servicesTitle: 'Face scan, routine, care, and progress in one path',
    previewDashboard: 'Preview dashboard',
    storyTitle: 'Understand what you see, then know what to do next',
    noticedTitle: 'What Skino noticed',
    noticedText:
      'Skino translates scan results into simple care language: visible skin type, concern level, routine reason, and when to ask a specialist.',
    routineTitle: 'Your skin. Your products. Your routine.',
    routineText:
      'The dashboard keeps daily steps, friendly reminders, and progress tracking easy to reach from the first screen.',
    memoryTitle: 'See how far your care journey has moved',
    safetyTitle: 'Smart AI with clear limits',
    aboutTitle: 'Team Kairo builds Skino for clear skin-care guidance',
    aboutText:
      'Skino is a wellness and skincare assistant, not a medical diagnosis system. The web app path keeps Laravel as the business API, Python as the AI service, and Vue.js as the customer experience.',
    footerTitle: 'Start understanding your skin with Skino.',
    footerText: 'Vue frontend, Laravel API, and Python AI service built for a complete skincare demo path.',
    openLogin: 'Open login',
    loginTitle: 'Welcome back to Skino',
    loginText:
      'Continue into your skin care workspace. This preview uses the final visual direction before API auth is connected.',
    loginBenefits: ['Private skin scan flow', 'Routine and appointment modules', 'Mobile-first Vue dashboard'],
    loginSubtitle: 'Preview the customer dashboard',
    email: 'Email',
    password: 'Password',
    goDashboard: 'Go to dashboard',
    dashboardTitle: 'Your Skino workspace',
    dashboardText: 'Mobile-responsive module cards for scan, routine, specialist, appointment, history, and progress.',
    todayPlan: "Today's beauty plan",
    score: 'Skin score',
    demo: 'Demo preview',
  },
  my: {
    home: 'ပင်မ',
    services: 'ဝန်ဆောင်မှု',
    about: 'အကြောင်း',
    contact: 'ဆက်သွယ်ရန်',
    login: 'Login',
    logout: 'Logout',
    brandNote: 'AI beauty care',
    eyebrow: 'Skino / အသားအရေ AI',
    heroTitle: ['Skino မှ', 'ကြိုဆိုပါတယ်', 'စကင်စမယ်'],
    heroBody:
      'မျက်နှာအလှအတွက် စကင်အရင်လုပ်ကြည့်ပါ။ Concern များကိုနားလည်ပြီး routine နှင့် progress ကို လွယ်လွယ်ကူကူဆက်သွားပါ။',
    startScan: 'စကင်စတင်မယ်',
    exploreServices: 'ဝန်ဆောင်မှု',
    howItWorks: 'ဘယ်လိုလုပ်သလဲ',
    heroChips: ['Guest scan', 'Setup မလို', 'Routine ready'],
    quickTitle: 'ပထမဆုံး စကင်လုပ်ရန် အသင့်',
    quickText: 'ဝက်ခြံအခြေအနေ၊ concern များကိုစစ်ပြီး နေ့စဉ် routine နှင့် progress tracking သို့ ဆက်သွားပါ။',
    actionCards: [
      ['မျက်နှာအလှ စကင်', 'ဝက်ခြံအခြေအနေနှင့် အသားအရေ score ကို အမြန်စစ်ပါ။'],
      ['နေ့စဉ်တိုးတက်မှု', 'နူးညံ့တဲ့ routine၊ သတိပေးချက်နဲ့ နောက်စကင်ချိန်များ။'],
      ['Specialist အကူအညီ', 'ဝက်ခြံအခြေအနေ များ၊ ပြင်း၊ မသေချာလျှင် အကြံပြုပါမယ်။'],
    ],
    howTitle: 'စကင်မှ နေ့စဉ် care အထိ အဆင့် ၃ ဆင့်',
    howSteps: [
      ['စကင်', 'မျက်နှာပုံကို upload/capture လုပ်ပြီး visible skin guidance ရယူပါ။'],
      ['နားလည်', 'Skin type၊ concern၊ score နှင့် routine အကြံပြုချက်ကို ကြည့်ပါ။'],
      ['တိုးတက်', 'နေ့စဉ် care လုပ်၊ progress ကြည့်ပြီး specialist help တောင်းနိုင်ပါတယ်။'],
    ],
    servicesTitle: 'Face scan, routine, care နှင့် progress ကို တစ်နေရာတည်းမှာ',
    previewDashboard: 'Dashboard ကြည့်မယ်',
    storyTitle: 'တွေ့ရတာကိုနားလည်ပြီး နောက်တစ်ဆင့်ကို သိပါ',
    noticedTitle: 'Skino တွေ့ရှိချက်',
    noticedText:
      'Skino က scan result ကို skin type၊ concern level၊ routine reason နှင့် specialist လိုအပ်ချိန်အဖြစ် ရိုးရိုးရှင်းရှင်း ပြပေးပါတယ်။',
    routineTitle: 'သင့် skin. သင့် products. သင့် routine.',
    routineText:
      'Dashboard ထဲမှာ daily steps၊ reminder နှင့် progress tracking ကို ပထမ screen ကနေ လွယ်လွယ်ကူကူသုံးနိုင်အောင်ထားပါတယ်။',
    memoryTitle: 'သင့် care journey တိုးတက်မှုကို ကြည့်ပါ',
    safetyTitle: 'AI ကို ရှင်းလင်းသော limit များနဲ့ သုံးမယ်',
    aboutTitle: 'Team Kairo က Skino ကို skincare guidance အတွက် တည်ဆောက်ထားပါတယ်',
    aboutText:
      'Skino သည် wellness နှင့် skincare assistant ဖြစ်ပြီး medical diagnosis system မဟုတ်ပါ။ Web app path မှာ Laravel API၊ Python AI service နှင့် Vue.js customer experience ကို သုံးထားပါတယ်။',
    footerTitle: 'Skino နဲ့ သင့် skin ကို စတင်နားလည်ပါ။',
    footerText: 'Vue frontend၊ Laravel API နှင့် Python AI service ပါဝင်သော skincare demo path။',
    openLogin: 'Login ဖွင့်မယ်',
    loginTitle: 'Skino မှ ကြိုဆိုပါတယ်',
    loginText: 'သင့် skin care workspace ထဲဝင်ပါ။ API auth မချိတ်ခင် final visual direction preview ဖြစ်ပါတယ်။',
    loginBenefits: ['Private skin scan flow', 'Routine နှင့် appointment module', 'Mobile-first Vue dashboard'],
    loginSubtitle: 'Customer dashboard preview',
    email: 'Email',
    password: 'Password',
    goDashboard: 'Dashboard သို့',
    dashboardTitle: 'သင့် Skino workspace',
    dashboardText: 'Scan, routine, specialist, appointment, history နှင့် progress module များကို mobile-responsive card များဖြင့်ထားပါတယ်။',
    todayPlan: 'ဒီနေ့ beauty plan',
    score: 'Skin score',
    demo: 'Demo preview',
  },
}

const t = computed(() => copy[language.value])

const publicNavItems = computed(() => [
  { label: t.value.home, view: 'home', target: 'home' },
  { label: t.value.services, view: 'services', target: 'services' },
  { label: t.value.about, view: 'about', target: 'about' },
  { label: t.value.contact, view: 'contact', target: 'contact' },
  { label: t.value.login, view: 'login' },
])

const howStepIcons = [scanIcon, reportIcon, routineIcon]
const actionIcons = [scanIcon, routineIcon, specialistIcon]

const howSteps = computed(() => t.value.howSteps.map(([title, text], index) => ({
  title,
  text,
  icon: howStepIcons[index],
})))

const quickActions = computed(() => t.value.actionCards.map(([title, text], index) => ({
  title,
  text,
  icon: actionIcons[index],
})))

const modules = computed(() => [
  {
    title: t.value.actionCards[0][0],
    subtitle: t.value.actionCards[0][1],
    icon: scanIcon,
    tone: '#ff6a00',
    status: 'Ready',
  },
  {
    title: t.value.actionCards[1][0],
    subtitle: t.value.actionCards[1][1],
    icon: routineIcon,
    tone: '#22b573',
    status: 'Daily',
  },
  {
    title: t.value.actionCards[2][0],
    subtitle: t.value.actionCards[2][1],
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
])

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

  const target = publicNavItems.value.find((item) => item.view === view)?.target
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

function setLanguage(nextLanguage) {
  language.value = nextLanguage
}

function syncStickyActions() {
  showStickyActions.value = window.scrollY > 360
}

onMounted(() => {
  syncStickyActions()
  window.addEventListener('scroll', syncStickyActions, { passive: true })
})

onUnmounted(() => {
  window.removeEventListener('scroll', syncStickyActions)
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
          <small>{{ t.brandNote }}</small>
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

      <div class="header-actions">
        <div class="language-toggle" aria-label="Language">
          <button type="button" :class="{ active: language === 'en' }" @click="setLanguage('en')">EN</button>
          <button type="button" :class="{ active: language === 'my' }" @click="setLanguage('my')">MM</button>
        </div>
        <button v-if="isLoggedIn" class="ghost-button" type="button" @click="signOut">{{ t.logout }}</button>
      </div>
    </header>

    <main>
      <template v-if="!isLoggedIn && activeView !== 'login'">
        <section id="home" class="landing-hero">
          <div class="home-copy">
            <p class="eyebrow">{{ t.eyebrow }}</p>
            <h1>
              <span v-for="(line, index) in t.heroTitle" :key="line" :class="{ 'orange-line': index === 2 }">
                {{ line }}
              </span>
            </h1>
            <div class="hero-actions">
              <button class="primary-button" type="button" @click="openView('login')">{{ t.startScan }}</button>
              <button class="ghost-button" type="button" @click="openView('services')">{{ t.exploreServices }}</button>
            </div>
            <p>{{ t.heroBody }}</p>
            <div class="hero-stat-strip" aria-label="Skino platform highlights">
              <span v-for="chip in t.heroChips" :key="chip">{{ chip }}</span>
            </div>
          </div>

          <div class="hero-actions-panel" aria-label="Skino quick actions">
            <div class="quick-panel-header">
              <span>01</span>
              <div>
                <p class="eyebrow">{{ t.howItWorks }}</p>
                <h2>{{ t.quickTitle }}</h2>
              </div>
            </div>
            <p>{{ t.quickText }}</p>
            <div class="quick-card-stack">
              <button
                v-for="(action, index) in quickActions"
                :key="action.title"
                class="quick-card"
                type="button"
                @click="index === 0 ? openView('login') : openView('services')"
              >
                <img :src="action.icon" alt="" />
                <span>
                  <strong>{{ action.title }}</strong>
                  <small>{{ action.text }}</small>
                </span>
              </button>
            </div>
          </div>
        </section>

        <section class="landing-section how-section" aria-labelledby="how-title">
          <div class="section-heading">
            <p class="eyebrow">{{ t.howItWorks }}</p>
            <h2 id="how-title">{{ t.howTitle }}</h2>
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
              <p class="eyebrow">{{ t.services }}</p>
              <h2 id="services-title">{{ t.servicesTitle }}</h2>
            </div>
            <button class="ghost-button" type="button" @click="openView('login')">{{ t.previewDashboard }}</button>
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
            <h2 id="story-title">{{ t.storyTitle }}</h2>
          </div>

          <div class="story-grid">
            <article class="score-panel">
              <p class="eyebrow">Analysis preview</p>
              <strong>82</strong>
              <span>{{ t.score }}</span>
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
              <h3>{{ t.noticedTitle }}</h3>
              <p>{{ t.noticedText }}</p>
            </article>
          </div>
        </section>

        <section class="landing-section routine-band" aria-labelledby="routine-title">
          <div>
            <p class="eyebrow">Routine / Daily care</p>
            <h2 id="routine-title">{{ t.routineTitle }}</h2>
            <p>{{ t.routineText }}</p>
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
              <h2 id="memory-title">{{ t.memoryTitle }}</h2>
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
            <h2 id="safety-title">{{ t.safetyTitle }}</h2>
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
            <h2 id="about-title">{{ t.aboutTitle }}</h2>
            <p>{{ t.aboutText }}</p>
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
          <h1>{{ t.loginTitle }}</h1>
          <p>{{ t.loginText }}</p>
          <div class="login-benefits">
            <span v-for="benefit in t.loginBenefits" :key="benefit">{{ benefit }}</span>
          </div>
        </div>

        <form class="login-card" @submit.prevent="enterDashboard">
          <div class="form-heading">
            <span class="brand-mark">
              <img :src="logo" alt="" />
            </span>
            <div>
              <h2>{{ t.login }}</h2>
              <p>{{ t.loginSubtitle }}</p>
            </div>
          </div>
          <label>
            {{ t.email }}
            <input type="email" value="demo@skino.local" autocomplete="email" />
          </label>
          <label>
            {{ t.password }}
            <input type="password" value="password" autocomplete="current-password" />
          </label>
          <button class="primary-button full-width" type="submit">{{ t.goDashboard }}</button>
        </form>
      </section>

      <section v-else class="dashboard-layout">
        <div class="dashboard-hero">
          <div>
            <p class="eyebrow">User dashboard</p>
            <h1>{{ t.dashboardTitle }}</h1>
            <p>{{ t.dashboardText }}</p>
          </div>
          <div class="health-card">
            <span>{{ t.score }}</span>
            <strong>82</strong>
            <small>{{ t.demo }}</small>
          </div>
        </div>

        <div class="dashboard-strip">
          <span>{{ t.todayPlan }}</span>
          <button class="primary-button" type="button">{{ t.startScan }}</button>
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
        <h2>{{ t.footerTitle }}</h2>
      </div>
      <div class="footer-contact">
        <strong>Skino — Your AI Skin Care Buddy</strong>
        <p>{{ t.footerText }}</p>
        <button class="primary-button" type="button" @click="openView('login')">{{ t.openLogin }}</button>
      </div>
    </footer>

    <div v-if="!isLoggedIn && activeView !== 'login' && showStickyActions" class="sticky-action-bar" aria-label="Quick actions">
      <button class="primary-button" type="button" @click="openView('login')">{{ t.startScan }}</button>
      <button class="ghost-button" type="button" @click="openView('services')">{{ t.howItWorks }}</button>
    </div>
  </div>
</template>
