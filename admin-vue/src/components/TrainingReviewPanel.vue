<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { fetchTrainingSamples, reviewTrainingSample } from '../services/adminTrainingApi'

const props = defineProps({
  token: {
    type: String,
    required: true,
  },
})

const reviewStatuses = ['pending', 'approved', 'rejected', 'needs_specialist']
const actions = [
  { value: 'approve', label: 'Approve' },
  { value: 'correct', label: 'Correct labels' },
  { value: 'needs_specialist', label: 'Needs specialist' },
  { value: 'reject', label: 'Reject' },
]

const state = reactive({
  samples: [],
  selected: null,
  loading: false,
  saving: false,
  error: '',
  message: '',
})

const filters = reactive({
  review_status: 'pending',
})

const reviewForm = reactive({
  action: 'approve',
  skin_type: '',
  acne_severity: '',
  concerns: '',
  review_note: '',
})

const selectedLabels = computed(() => state.selected?.corrected_labels || state.selected?.snapshot_payload || {})

onMounted(loadSamples)

async function loadSamples() {
  state.loading = true
  clearFeedback()

  try {
    const payload = await fetchTrainingSamples(props.token, filters)
    state.samples = payload.data || []
    state.selected = state.selected
      ? state.samples.find((sample) => sample.id === state.selected.id) || state.samples[0] || null
      : state.samples[0] || null
    fillReviewForm()
  } catch (error) {
    state.error = error.message
  } finally {
    state.loading = false
  }
}

function selectSample(sample) {
  state.selected = sample
  clearFeedback()
  fillReviewForm()
}

function fillReviewForm() {
  const labels = selectedLabels.value
  reviewForm.action = 'approve'
  reviewForm.skin_type = labels.skin_type || ''
  reviewForm.acne_severity = labels.acne_severity || ''
  reviewForm.concerns = normalizeConcerns(labels.concerns).join(', ')
  reviewForm.review_note = state.selected?.review_note || ''
}

async function submitReview() {
  if (!state.selected) {
    return
  }

  state.saving = true
  clearFeedback()

  try {
    const payload = {
      action: reviewForm.action,
      review_note: reviewForm.review_note || null,
    }

    if (reviewForm.action === 'correct') {
      payload.corrected_labels = {
        skin_type: reviewForm.skin_type || null,
        acne_severity: reviewForm.acne_severity || null,
        concerns: reviewForm.concerns
          .split(',')
          .map((concern) => concern.trim())
          .filter(Boolean),
      }
    }

    const response = await reviewTrainingSample(props.token, state.selected.id, payload)
    state.selected = response.data
    state.message = 'Review saved.'
    await loadSamples()
  } catch (error) {
    state.error = error.message
  } finally {
    state.saving = false
  }
}

function normalizeConcerns(concerns) {
  if (!Array.isArray(concerns)) {
    return []
  }

  return concerns.map((concern) => (typeof concern === 'string' ? concern : concern.name)).filter(Boolean)
}

function clearFeedback() {
  state.error = ''
  state.message = ''
}
</script>

<template>
  <section class="training-workspace" aria-labelledby="training-review-title">
    <div class="contacts-header">
      <div>
        <p class="eyebrow">AI learning review</p>
        <h2 id="training-review-title">Only reviewed, consented scans can improve the model.</h2>
        <p>
          Approve clean samples, reject unsafe data, correct labels, or send unclear cases to specialist review.
          This is the bridge between user trust and stronger AI.
        </p>
      </div>
      <button class="ghost-action" :disabled="state.loading" type="button" @click="loadSamples">Refresh</button>
    </div>

    <div class="review-grid">
      <article class="contacts-table-card">
        <div class="table-heading">
          <h3>Review queue</h3>
          <span>{{ state.loading ? 'Loading' : `${state.samples.length} shown` }}</span>
        </div>

        <form class="contacts-filters" @submit.prevent="loadSamples">
          <select v-model="filters.review_status">
            <option value="">All review states</option>
            <option v-for="status in reviewStatuses" :key="status" :value="status">{{ status }}</option>
          </select>
          <button class="ghost-action" :disabled="state.loading" type="submit">Filter</button>
        </form>

        <p v-if="state.error" class="form-error" role="alert">{{ state.error }}</p>
        <p v-if="state.message" class="form-success" role="status">{{ state.message }}</p>

        <div class="sample-list">
          <button
            v-for="sample in state.samples"
            :key="sample.id"
            class="sample-card"
            :class="{ 'sample-card-active': state.selected?.id === sample.id }"
            type="button"
            @click="selectSample(sample)"
          >
            <span class="status-soft">{{ sample.review_status }}</span>
            <strong>#{{ sample.id }} · {{ sample.snapshot_payload?.skin_type || 'unknown' }}</strong>
            <small>
              acne {{ sample.snapshot_payload?.acne_severity || 'none' }} ·
              {{ sample.image?.privacy_status || 'privacy unknown' }}
            </small>
          </button>
          <div v-if="!state.loading && state.samples.length === 0" class="contacts-empty">
            No samples in this review state.
          </div>
        </div>
      </article>

      <aside class="review-detail-card">
        <template v-if="state.selected">
          <div class="table-heading">
            <h3>Sample #{{ state.selected.id }}</h3>
            <span>{{ state.selected.training_status }}</span>
          </div>

          <div class="label-summary">
            <div>
              <small>Skin type</small>
              <strong>{{ selectedLabels.skin_type || 'unknown' }}</strong>
            </div>
            <div>
              <small>Acne severity</small>
              <strong>{{ selectedLabels.acne_severity || 'none' }}</strong>
            </div>
            <div>
              <small>Score</small>
              <strong>{{ selectedLabels.skin_health_score || '--' }}</strong>
            </div>
          </div>

          <div class="sample-meta">
            <span>Consent policy: {{ state.selected.consent?.policy_version || 'unknown' }}</span>
            <span>Privacy: {{ state.selected.image?.privacy_status || 'unknown' }}</span>
            <span>Source: {{ state.selected.label_source }}</span>
          </div>

          <form class="contact-form" @submit.prevent="submitReview">
            <label>
              Review action
              <select v-model="reviewForm.action">
                <option v-for="action in actions" :key="action.value" :value="action.value">
                  {{ action.label }}
                </option>
              </select>
            </label>

            <div class="form-row">
              <label>
                Correct skin type
                <input v-model.trim="reviewForm.skin_type" :disabled="reviewForm.action !== 'correct'" />
              </label>
              <label>
                Correct severity
                <select v-model="reviewForm.acne_severity" :disabled="reviewForm.action !== 'correct'">
                  <option value="">No change</option>
                  <option value="none">none</option>
                  <option value="mild">mild</option>
                  <option value="moderate">moderate</option>
                  <option value="severe">severe</option>
                </select>
              </label>
            </div>

            <label>
              Correct concerns
              <input
                v-model.trim="reviewForm.concerns"
                :disabled="reviewForm.action !== 'correct'"
                placeholder="acne, dark_spots"
              />
            </label>

            <label>
              Review note
              <textarea v-model.trim="reviewForm.review_note" rows="4" placeholder="Why did you approve, reject, or correct this sample?"></textarea>
            </label>

            <button class="primary-action" :disabled="state.saving" type="submit">
              {{ state.saving ? 'Saving...' : 'Save Review' }}
            </button>
          </form>
        </template>

        <div v-else class="contacts-empty">Select a sample to review.</div>
      </aside>
    </div>
  </section>
</template>
