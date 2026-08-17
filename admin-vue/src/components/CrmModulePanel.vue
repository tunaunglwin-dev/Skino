<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { fetchContacts } from '../services/adminContactsApi'
import {
  addCrmNote,
  createCrmRecord,
  fetchCrmRecord,
  fetchCrmRecords,
  updateCrmRecord,
} from '../services/adminCrmApi'

const props = defineProps({
  token: {
    type: String,
    required: true,
  },
})

const stages = ['new', 'contacted', 'appointment_scheduled', 'completed', 'closed']
const priorities = ['low', 'normal', 'high', 'urgent']
const appointmentStatuses = ['not_scheduled', 'scheduled', 'completed', 'cancelled']

const state = reactive({
  records: [],
  contacts: [],
  selected: null,
  loading: false,
  saving: false,
  error: '',
  message: '',
})

const filters = reactive({
  search: '',
  stage: '',
  priority: '',
})

const form = reactive(emptyForm())
const note = reactive({
  note_type: 'appointment',
  body: '',
})
const view = ref('cards')
const mode = ref('view')

const clientContacts = computed(() =>
  state.contacts.filter((contact) => ['user', 'lead'].includes(contact.contact_type)),
)
const specialistContacts = computed(() =>
  state.contacts.filter((contact) => contact.contact_type === 'specialist'),
)
const selectedTitle = computed(() =>
  mode.value === 'create'
    ? 'Create appointment card'
    : state.selected?.title || 'Appointment detail',
)
const stageCounts = computed(() =>
  stages.map((stage) => ({
    stage,
    count: state.records.filter((record) => record.stage === stage).length,
  })),
)

onMounted(async () => {
  await Promise.all([loadContacts(), loadRecords()])
})

async function loadContacts() {
  try {
    const payload = await fetchContacts(props.token, {})
    state.contacts = payload.data || []
  } catch (error) {
    state.error = error.message
  }
}

async function loadRecords() {
  state.loading = true
  clearFeedback()

  try {
    const payload = await fetchCrmRecords(props.token, filters)
    state.records = payload.data || []
  } catch (error) {
    state.error = error.message
  } finally {
    state.loading = false
  }
}

async function openRecord(record) {
  clearFeedback()
  view.value = 'detail'
  mode.value = 'view'

  try {
    const payload = await fetchCrmRecord(props.token, record.id)
    state.selected = payload.data
    fillForm(payload.data)
  } catch (error) {
    state.error = error.message
  }
}

function backToCards() {
  view.value = 'cards'
  mode.value = 'view'
  state.selected = null
  note.body = ''
  clearFeedback()
}

function startCreate() {
  clearFeedback()
  view.value = 'detail'
  mode.value = 'create'
  state.selected = null
  Object.assign(form, emptyForm())
  note.body = ''
}

function startEdit() {
  mode.value = 'edit'
  clearFeedback()
}

function cancelEdit() {
  if (state.selected) {
    fillForm(state.selected)
    mode.value = 'view'
    clearFeedback()
    return
  }

  backToCards()
}

async function saveRecord() {
  state.saving = true
  clearFeedback()

  try {
    const payload = recordPayload()
    const response =
      mode.value === 'edit' && state.selected
        ? await updateCrmRecord(props.token, state.selected.id, payload)
        : await createCrmRecord(props.token, payload)

    state.selected = response.data
    mode.value = 'view'
    state.message = 'Appointment card saved.'
    await loadRecords()
    await openRecord(state.selected)
  } catch (error) {
    state.error = error.message
  } finally {
    state.saving = false
  }
}

async function saveNote() {
  if (!state.selected || !note.body.trim()) {
    return
  }

  state.saving = true
  clearFeedback()

  try {
    await addCrmNote(props.token, state.selected.id, {
      note_type: note.note_type,
      body: note.body.trim(),
    })
    note.body = ''
    state.message = 'CRM note saved.'
    await openRecord(state.selected)
  } catch (error) {
    state.error = error.message
  } finally {
    state.saving = false
  }
}

function chooseStage(stage) {
  filters.stage = filters.stage === stage ? '' : stage
  loadRecords()
}

function fillForm(record) {
  Object.assign(form, {
    contact_id: record.contact?.id?.toString() || '',
    specialist_contact_id: record.specialist?.id?.toString() || '',
    title: record.title || '',
    stage: record.stage || 'new',
    priority: record.priority || 'normal',
    appointment_status: record.appointment_status || 'not_scheduled',
    scheduled_at: record.scheduled_at ? record.scheduled_at.slice(0, 16) : '',
    beauty_goal: record.beauty_goal || '',
    concern_summary: record.concern_summary || '',
    tags: (record.tags || []).join(', '),
  })
}

function emptyForm() {
  return {
    contact_id: '',
    specialist_contact_id: '',
    title: '',
    stage: 'new',
    priority: 'normal',
    appointment_status: 'not_scheduled',
    scheduled_at: '',
    beauty_goal: '',
    concern_summary: '',
    tags: '',
  }
}

function recordPayload() {
  return {
    contact_id: Number(form.contact_id),
    specialist_contact_id: form.specialist_contact_id ? Number(form.specialist_contact_id) : null,
    title: form.title.trim(),
    stage: form.stage,
    priority: form.priority,
    appointment_status: form.appointment_status,
    scheduled_at: form.scheduled_at || null,
    beauty_goal: form.beauty_goal.trim() || null,
    concern_summary: form.concern_summary.trim() || null,
    tags: form.tags
      .split(',')
      .map((tag) => tag.trim())
      .filter(Boolean),
  }
}

function clearFeedback() {
  state.error = ''
  state.message = ''
}

function displayDate(value) {
  if (!value) {
    return 'Not scheduled'
  }

  return new Intl.DateTimeFormat(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(new Date(value))
}

function priorityLabel(priority) {
  return priority === 'urgent' ? 'urgent care' : priority
}
</script>

<template>
  <section class="crm-workspace" aria-labelledby="crm-title">
    <div v-if="view === 'cards'" class="workspace-action-row">
      <h2 id="crm-title">Appointment cards</h2>
      <button class="primary-action" type="button" @click="startCreate">Create Appointment</button>
    </div>

    <template v-if="view === 'cards'">
      <div class="pipeline-strip">
        <button
          v-for="item in stageCounts"
          :key="item.stage"
          class="pipeline-stage"
          :class="{ 'pipeline-stage-active': filters.stage === item.stage }"
          type="button"
          @click="chooseStage(item.stage)"
        >
          <strong>{{ item.count }}</strong>
          <span>{{ item.stage.replaceAll('_', ' ') }}</span>
        </button>
      </div>

      <form class="contacts-filters contact-card-filters" @submit.prevent="loadRecords">
        <input v-model.trim="filters.search" type="search" placeholder="Search appointment, goal, contact" />
        <select v-model="filters.priority">
          <option value="">All priority</option>
          <option v-for="priority in priorities" :key="priority" :value="priority">{{ priority }}</option>
        </select>
        <button class="ghost-action" :disabled="state.loading" type="submit">Search</button>
      </form>

      <p v-if="state.error" class="form-error" role="alert">{{ state.error }}</p>
      <p v-if="state.message" class="form-success" role="status">{{ state.message }}</p>

      <div class="appointment-card-grid">
        <button
          v-for="record in state.records"
          :key="record.id"
          class="appointment-card"
          type="button"
          @click="openRecord(record)"
        >
          <span class="appointment-card-top">
            <span class="status-soft">{{ record.stage.replaceAll('_', ' ') }}</span>
            <span class="priority-pill" :data-priority="record.priority">{{ priorityLabel(record.priority) }}</span>
          </span>
          <strong>{{ record.title }}</strong>
          <span class="appointment-people">
            <span>
              <small>Client</small>
              {{ record.contact?.display_name || 'No client linked' }}
            </span>
            <span>
              <small>Specialist</small>
              {{ record.specialist?.display_name || 'Not assigned' }}
            </span>
          </span>
          <span class="appointment-meta">
            <span>{{ record.appointment_status.replaceAll('_', ' ') }}</span>
            <span>{{ displayDate(record.scheduled_at) }}</span>
          </span>
          <span class="appointment-goal">{{ record.beauty_goal || 'No beauty goal recorded' }}</span>
        </button>
      </div>

      <div v-if="!state.loading && state.records.length === 0" class="contacts-empty">
        No appointment cards found. Create the first specialist request.
      </div>
    </template>

    <template v-else>
      <button class="back-action" type="button" @click="backToCards">
        <span aria-hidden="true">‹</span>
        Appointment cards
      </button>

      <article class="profile-detail-shell">
        <header class="profile-detail-hero appointment-detail-hero">
          <span class="appointment-avatar">
            <span></span>
          </span>

          <div>
            <p class="eyebrow">{{ form.stage.replaceAll('_', ' ') }}</p>
            <h2>{{ selectedTitle }}</h2>
            <p>{{ form.beauty_goal || 'Appointment request and follow-up details.' }}</p>
          </div>

          <div class="profile-detail-actions">
            <button v-if="mode === 'view'" class="ghost-action" type="button" @click="startEdit">Edit</button>
            <button v-if="mode !== 'view'" class="ghost-action" type="button" @click="cancelEdit">
              Cancel
            </button>
          </div>
        </header>

        <p v-if="state.error" class="form-error" role="alert">{{ state.error }}</p>
        <p v-if="state.message" class="form-success" role="status">{{ state.message }}</p>

        <section v-if="mode === 'view' && state.selected" class="profile-detail-grid">
          <div class="profile-info-card">
            <h3>Appointment</h3>
            <dl>
              <div><dt>Stage</dt><dd>{{ state.selected.stage.replaceAll('_', ' ') }}</dd></div>
              <div><dt>Status</dt><dd>{{ state.selected.appointment_status.replaceAll('_', ' ') }}</dd></div>
              <div><dt>Priority</dt><dd>{{ priorityLabel(state.selected.priority) }}</dd></div>
              <div><dt>Scheduled</dt><dd>{{ displayDate(state.selected.scheduled_at) }}</dd></div>
            </dl>
          </div>

          <div class="profile-info-card">
            <h3>People</h3>
            <dl>
              <div><dt>Client</dt><dd>{{ state.selected.contact?.display_name || 'None' }}</dd></div>
              <div><dt>Client phone</dt><dd>{{ state.selected.contact?.phone || 'None' }}</dd></div>
              <div><dt>Client email</dt><dd>{{ state.selected.contact?.email || state.selected.contact?.gmail_email || 'None' }}</dd></div>
              <div><dt>Specialist</dt><dd>{{ state.selected.specialist?.display_name || 'Not assigned' }}</dd></div>
              <div><dt>Source</dt><dd>{{ state.selected.source }}</dd></div>
            </dl>
          </div>

          <div class="profile-info-card profile-info-card-wide">
            <h3>Concern summary</h3>
            <p>{{ state.selected.concern_summary || 'No concern summary yet.' }}</p>
          </div>
        </section>

        <form v-else class="profile-edit-form" @submit.prevent="saveRecord">
          <div class="profile-form-section">
            <h3>People</h3>
            <label>
              Client contact
              <select v-model="form.contact_id" required>
                <option value="">Choose client</option>
                <option v-for="contact in clientContacts" :key="contact.id" :value="contact.id">
                  {{ contact.display_name }} - {{ contact.contact_type }}
                </option>
              </select>
            </label>

            <label>
              Specialist
              <select v-model="form.specialist_contact_id">
                <option value="">No specialist assigned</option>
                <option v-for="contact in specialistContacts" :key="contact.id" :value="contact.id">
                  {{ contact.display_name }}
                </option>
              </select>
            </label>

            <label>
              Title
              <input v-model.trim="form.title" required maxlength="160" placeholder="Acne specialist consultation" />
            </label>
          </div>

          <div class="profile-form-section">
            <h3>Appointment status</h3>
            <div class="form-row">
              <label>
                Stage
                <select v-model="form.stage">
                  <option v-for="stage in stages" :key="stage" :value="stage">{{ stage }}</option>
                </select>
              </label>
              <label>
                Priority
                <select v-model="form.priority">
                  <option v-for="priority in priorities" :key="priority" :value="priority">{{ priority }}</option>
                </select>
              </label>
            </div>

            <div class="form-row">
              <label>
                Appointment
                <select v-model="form.appointment_status">
                  <option v-for="status in appointmentStatuses" :key="status" :value="status">{{ status }}</option>
                </select>
              </label>
              <label>
                Scheduled time
                <input v-model="form.scheduled_at" type="datetime-local" />
              </label>
            </div>
          </div>

          <div class="profile-form-section profile-form-section-wide">
            <h3>Care context</h3>
            <label>
              Beauty goal
              <input v-model.trim="form.beauty_goal" maxlength="160" placeholder="Improve acne before event" />
            </label>
            <label>
              Concern summary
              <textarea v-model.trim="form.concern_summary" rows="3" placeholder="Scan severity, user concern, specialist notes"></textarea>
            </label>
            <label>
              Tags
              <input v-model.trim="form.tags" placeholder="acne, specialist, vip" />
            </label>
          </div>

          <button class="primary-action" :disabled="state.saving" type="submit">
            {{ state.saving ? 'Saving...' : mode === 'edit' ? 'Save Appointment' : 'Create Appointment' }}
          </button>
        </form>

        <section v-if="state.selected" class="notes-panel profile-notes-panel">
          <h3>Follow-up notes</h3>
          <form class="note-form" @submit.prevent="saveNote">
            <select v-model="note.note_type">
              <option value="appointment">appointment</option>
              <option value="crm">crm</option>
              <option value="safety">safety</option>
              <option value="follow_up">follow_up</option>
            </select>
            <textarea v-model.trim="note.body" rows="3" placeholder="Add appointment or follow-up note"></textarea>
            <button class="ghost-action" :disabled="state.saving || !note.body.trim()" type="submit">Add Note</button>
          </form>

          <div class="notes-list">
            <p v-if="!state.selected.notes?.length">No CRM notes yet.</p>
            <article v-for="item in state.selected.notes" :key="item.id" class="note-item">
              <strong>{{ item.note_type }}</strong>
              <p>{{ item.body }}</p>
            </article>
          </div>
        </section>
      </article>
    </template>
  </section>
</template>
