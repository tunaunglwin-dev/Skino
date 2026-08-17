<script setup>
import { computed, ref } from 'vue'
import { adminModules } from '../data/adminModules'
import BrandMark from './BrandMark.vue'
import CareOperationsPanel from './CareOperationsPanel.vue'
import CrmModulePanel from './CrmModulePanel.vue'
import ContactsModulePanel from './ContactsModulePanel.vue'
import ScanReviewPanel from './ScanReviewPanel.vue'
import TrainingReviewPanel from './TrainingReviewPanel.vue'

const props = defineProps({
  user: {
    type: Object,
    required: true,
  },
  loading: {
    type: Boolean,
    required: true,
  },
  token: {
    type: String,
    required: true,
  },
})

const emit = defineEmits(['logout'])
const adminName = computed(() => props.user?.name || 'Admin')
const activeModule = ref('')
const activeModuleInfo = computed(() =>
  adminModules.find((module) => module.title === activeModule.value),
)

function openModule(module) {
  activeModule.value = module.title
}

function closeModule() {
  activeModule.value = ''
}
</script>

<template>
  <section class="dashboard-screen">
    <header class="topbar">
      <div class="topbar-brand">
        <BrandMark />
        <div>
          <p>Skino</p>
          <h1>Admin Workspace</h1>
        </div>
      </div>

      <div class="topbar-actions">
        <div class="admin-chip">
          <span>{{ adminName.charAt(0).toUpperCase() }}</span>
          <div>
            <p>{{ adminName }}</p>
            <small>Administrator</small>
          </div>
        </div>
        <button class="ghost-action" :disabled="loading" type="button" @click="emit('logout')">
          Logout
        </button>
      </div>
    </header>

    <section v-if="!activeModule" class="admin-home" aria-label="Admin overview">
      <section class="module-launcher" aria-label="Admin modules">
        <button
          v-for="module in adminModules"
          :key="module.title"
          class="module-tile"
          type="button"
          :style="{ '--module-accent': module.accent }"
          @click="openModule(module)"
        >
          <span v-if="module.image" class="module-image-shell" aria-hidden="true">
            <img :src="module.image" alt="" />
          </span>
          <span v-else class="module-icon" :data-icon="module.icon" aria-hidden="true"></span>
          <span class="module-title">{{ module.title }}</span>
          <span class="module-subtitle">{{ module.subtitle }}</span>
        </button>
      </section>
    </section>

    <section v-else class="module-page">
      <button class="back-action" type="button" @click="closeModule">
        <span aria-hidden="true">‹</span>
        Modules
      </button>

      <div class="module-page-heading" :style="{ '--module-accent': activeModuleInfo?.accent }">
        <span v-if="activeModuleInfo?.image" class="module-image-shell module-image-shell-small" aria-hidden="true">
          <img :src="activeModuleInfo.image" alt="" />
        </span>
        <span v-else class="module-icon" :data-icon="activeModuleInfo?.icon" aria-hidden="true"></span>
        <div>
          <h2>{{ activeModuleInfo?.title }}</h2>
        </div>
      </div>

      <ContactsModulePanel v-if="activeModule === 'Contacts'" :token="token" />
      <CrmModulePanel v-else-if="activeModule === 'CRM'" :token="token" />
      <CareOperationsPanel v-else-if="activeModule === 'Care'" :token="token" />
      <ScanReviewPanel v-else-if="activeModule === 'Scan Review'" :token="token" />
      <TrainingReviewPanel v-else-if="activeModule === 'AI Training'" :token="token" />
      <div v-else class="module-placeholder">
        <h3>{{ activeModule }} workspace</h3>
        <p v-if="activeModule === 'Care'">
          Routine operations will show active care plans, morning/night progress, follow-up due dates, and the source scan.
        </p>
        <p v-else-if="activeModule === 'Scan Review'">
          Scan review will show scan quality, bad scans, selected routine source scans, and user-visible results.
        </p>
      </div>
    </section>
  </section>
</template>
