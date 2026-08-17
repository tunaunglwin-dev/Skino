<script setup>
import { computed, onMounted, reactive } from 'vue'
import { fetchScanReviews } from '../services/adminOpsApi'

const props = defineProps({
  token: {
    type: String,
    required: true,
  },
})

const state = reactive({
  scans: [],
  loading: false,
  error: '',
})

const filters = reactive({
  search: '',
  quality: 'all',
  skin_type: '',
})

const summary = computed(() => ({
  shown: state.scans.length,
  bad: state.scans.filter((scan) => scan.scan_quality?.needs_retake).length,
  training: state.scans.filter((scan) => scan.privacy?.training_queued).length,
}))

onMounted(loadScans)

async function loadScans() {
  state.loading = true
  state.error = ''

  try {
    const payload = await fetchScanReviews(props.token, filters)
    state.scans = payload.data || []
  } catch (error) {
    state.error = error.message
  } finally {
    state.loading = false
  }
}

function percent(value) {
  if (value === null || value === undefined) {
    return '--'
  }

  return `${Math.round(Number(value))}%`
}

function formatDate(value) {
  if (!value) {
    return '--'
  }

  return new Date(value).toLocaleString()
}
</script>

<template>
  <section class="ops-workspace" aria-labelledby="scan-review-title">
    <div class="contacts-header">
      <div>
        <p class="eyebrow">Scan review</p>
        <h2 id="scan-review-title">Quality, result, and AI learning visibility.</h2>
        <p>
          Review user scans, identify unstable lighting or framing, and see which scans are queued for model learning.
        </p>
      </div>
      <button class="ghost-action" :disabled="state.loading" type="button" @click="loadScans">Refresh</button>
    </div>

    <section class="admin-metrics">
      <article class="admin-metric-card" data-tone="orange">
        <span>Shown scans</span>
        <strong>{{ summary.shown }}</strong>
        <small>Current review filter</small>
      </article>
      <article class="admin-metric-card" data-tone="green">
        <span>Bad scans</span>
        <strong>{{ summary.bad }}</strong>
        <small>Retake recommended</small>
      </article>
      <article class="admin-metric-card" data-tone="orange">
        <span>Training queued</span>
        <strong>{{ summary.training }}</strong>
        <small>Consent-based learning</small>
      </article>
    </section>

    <form class="ops-filters" @submit.prevent="loadScans">
      <input v-model.trim="filters.search" type="search" placeholder="Search user name or email" />
      <select v-model="filters.quality">
        <option value="all">All quality</option>
        <option value="good">Good scans</option>
        <option value="bad">Bad scans</option>
      </select>
      <input v-model.trim="filters.skin_type" placeholder="Skin type, e.g. oily" />
      <button class="ghost-action" :disabled="state.loading" type="submit">Filter</button>
    </form>

    <p v-if="state.error" class="form-error" role="alert">{{ state.error }}</p>

    <section class="ops-card-grid ops-card-grid-compact">
      <article v-for="scan in state.scans" :key="scan.id" class="ops-card">
        <div class="ops-card-top">
          <span class="status-soft" :data-state="scan.scan_quality?.needs_retake ? 'bad' : 'good'">
            {{ scan.scan_quality?.needs_retake ? 'bad scan' : 'stable scan' }}
          </span>
          <strong>Scan #{{ scan.id }} · score {{ scan.skin_health_score ?? '--' }}</strong>
        </div>
        <p>
          {{ scan.user?.name || scan.user?.email || 'Unknown user' }} ·
          {{ scan.skin_type || 'unknown' }} · acne {{ scan.acne_severity || 'none' }}
        </p>
        <div class="scan-quality-row">
          <span>Light {{ percent(scan.scan_quality?.lighting_score) }}</span>
          <span>Face {{ percent(scan.scan_quality?.face_score) }}</span>
          <span>Center {{ percent(scan.scan_quality?.center_score) }}</span>
        </div>
        <div class="sample-meta">
          <span v-for="concern in scan.concerns" :key="concern">{{ concern }}</span>
          <span>{{ scan.privacy?.training_queued ? 'training queued' : 'not queued' }}</span>
          <span>{{ formatDate(scan.created_at) }}</span>
        </div>
      </article>

      <div v-if="!state.loading && state.scans.length === 0" class="contacts-empty">
        No scans found for this filter.
      </div>
    </section>
  </section>
</template>
