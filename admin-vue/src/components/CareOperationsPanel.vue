<script setup>
import { computed, onMounted, reactive } from 'vue'
import { fetchCareRoutines } from '../services/adminOpsApi'

const props = defineProps({
  token: {
    type: String,
    required: true,
  },
})

const state = reactive({
  routines: [],
  loading: false,
  error: '',
})

const filters = reactive({
  search: '',
  status: 'active',
})

const summary = computed(() => ({
  active: state.routines.filter((routine) => routine.is_active).length,
  dueSoon: state.routines.filter((routine) => routine.follow_up_due_in <= 3).length,
  completed: state.routines.reduce((total, routine) => total + (routine.progress?.completed_days || 0), 0),
}))

onMounted(loadRoutines)

async function loadRoutines() {
  state.loading = true
  state.error = ''

  try {
    const payload = await fetchCareRoutines(props.token, filters)
    state.routines = payload.data || []
  } catch (error) {
    state.error = error.message
  } finally {
    state.loading = false
  }
}

function formatDate(value) {
  if (!value) {
    return '--'
  }

  return new Date(value).toLocaleDateString()
}
</script>

<template>
  <section class="ops-workspace" aria-labelledby="care-ops-title">
    <div class="contacts-header">
      <div>
        <p class="eyebrow">Care operations</p>
        <h2 id="care-ops-title">Routine progress and follow-up control.</h2>
        <p>
          Track active care plans by user, source scan, completion rhythm, and next follow-up scan timing.
        </p>
      </div>
      <button class="ghost-action" :disabled="state.loading" type="button" @click="loadRoutines">Refresh</button>
    </div>

    <section class="admin-metrics">
      <article class="admin-metric-card" data-tone="orange">
        <span>Active routines</span>
        <strong>{{ summary.active }}</strong>
        <small>Currently running care plans</small>
      </article>
      <article class="admin-metric-card" data-tone="green">
        <span>Follow-up soon</span>
        <strong>{{ summary.dueSoon }}</strong>
        <small>Due in 3 days or less</small>
      </article>
      <article class="admin-metric-card" data-tone="orange">
        <span>Completed days</span>
        <strong>{{ summary.completed }}</strong>
        <small>Morning and night both done</small>
      </article>
    </section>

    <form class="ops-filters" @submit.prevent="loadRoutines">
      <input v-model.trim="filters.search" type="search" placeholder="Search user name or email" />
      <select v-model="filters.status">
        <option value="">All routines</option>
        <option value="active">Active</option>
        <option value="stopped">Stopped</option>
      </select>
      <button class="ghost-action" :disabled="state.loading" type="submit">Filter</button>
    </form>

    <p v-if="state.error" class="form-error" role="alert">{{ state.error }}</p>

    <section class="ops-card-grid">
      <article v-for="routine in state.routines" :key="routine.id" class="ops-card">
        <div class="ops-card-top">
          <span class="status-soft">{{ routine.is_active ? 'active' : 'stopped' }}</span>
          <strong>{{ routine.routine?.name || 'Care routine' }}</strong>
        </div>
        <p>{{ routine.routine?.reason || 'Routine created from scan result.' }}</p>
        <dl class="ops-detail-grid">
          <div>
            <dt>User</dt>
            <dd>{{ routine.user?.name || routine.user?.email || 'Unknown user' }}</dd>
          </div>
          <div>
            <dt>Source scan</dt>
            <dd>#{{ routine.source_scan?.id || '--' }} · score {{ routine.source_scan?.score ?? '--' }}</dd>
          </div>
          <div>
            <dt>Follow-up</dt>
            <dd>{{ routine.follow_up_due_in }} days left</dd>
          </div>
          <div>
            <dt>Progress</dt>
            <dd>{{ routine.progress?.completed_days || 0 }} full days · {{ routine.progress?.partial_days || 0 }} partial</dd>
          </div>
          <div>
            <dt>Started</dt>
            <dd>{{ formatDate(routine.started_at) }}</dd>
          </div>
        </dl>
      </article>

      <div v-if="!state.loading && state.routines.length === 0" class="contacts-empty">
        No care routines found for this filter.
      </div>
    </section>
  </section>
</template>
