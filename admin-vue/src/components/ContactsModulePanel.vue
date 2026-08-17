<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import {
  addContactNote,
  createContact,
  fetchContact,
  fetchContacts,
  updateContact,
  uploadContactAvatar,
} from '../services/adminContactsApi'

const props = defineProps({
  token: {
    type: String,
    required: true,
  },
})

const contactTypes = ['user', 'specialist', 'seller', 'vendor', 'internal', 'lead']
const statuses = ['active', 'archived', 'blocked']
const sources = ['google', 'manual', 'system']
const avatarTypes = ['specialist', 'seller', 'vendor']

const state = reactive({
  contacts: [],
  selected: null,
  loading: false,
  saving: false,
  error: '',
  message: '',
})

const filters = reactive({
  search: '',
  contact_type: '',
  status: '',
  source: '',
})

const form = reactive(emptyContactForm())
const note = reactive({
  note_type: 'general',
  body: '',
})

const view = ref('cards')
const mode = ref('view')
const avatarFile = ref(null)

const selectedTitle = computed(() =>
  mode.value === 'create'
    ? 'Create contact profile'
    : state.selected?.display_name || 'Contact profile',
)
const canUploadAvatar = computed(() => avatarTypes.includes(form.contact_type))
const contactCounts = computed(() =>
  contactTypes.map((type) => ({
    type,
    count: state.contacts.filter((contact) => contact.contact_type === type).length,
  })),
)

onMounted(loadContacts)

async function loadContacts() {
  state.loading = true
  clearFeedback()

  try {
    const payload = await fetchContacts(props.token, filters)
    state.contacts = payload.data || []
  } catch (error) {
    state.error = error.message
  } finally {
    state.loading = false
  }
}

async function openContact(contact) {
  clearFeedback()
  mode.value = 'view'
  view.value = 'detail'

  try {
    const payload = await fetchContact(props.token, contact.id)
    state.selected = payload.data
    fillForm(payload.data)
    avatarFile.value = null
  } catch (error) {
    state.error = error.message
  }
}

function backToCards() {
  view.value = 'cards'
  mode.value = 'view'
  state.selected = null
  avatarFile.value = null
  clearFeedback()
}

function startCreate() {
  clearFeedback()
  mode.value = 'create'
  view.value = 'detail'
  state.selected = null
  avatarFile.value = null
  Object.assign(form, emptyContactForm())
  note.body = ''
  note.note_type = 'general'
}

function startEdit() {
  mode.value = 'edit'
  clearFeedback()
}

function cancelEdit() {
  if (state.selected) {
    fillForm(state.selected)
    mode.value = 'view'
    avatarFile.value = null
    clearFeedback()
    return
  }

  backToCards()
}

async function saveContact() {
  state.saving = true
  clearFeedback()

  try {
    const payload = contactPayload()
    const response =
      mode.value === 'edit' && state.selected
        ? await updateContact(props.token, state.selected.id, payload)
        : await createContact(props.token, payload)

    state.selected = response.data
    mode.value = 'view'

    if (avatarFile.value && canUploadAvatar.value) {
      const avatarResponse = await uploadContactAvatar(props.token, state.selected.id, avatarFile.value)
      state.selected = avatarResponse.data
    }

    state.message = 'Contact profile saved.'
    await loadContacts()
    if (state.selected) {
      await openContact(state.selected)
    }
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
    await addContactNote(props.token, state.selected.id, {
      note_type: note.note_type,
      body: note.body.trim(),
    })
    note.body = ''
    state.message = 'Note saved.'
    await openContact(state.selected)
  } catch (error) {
    state.error = error.message
  } finally {
    state.saving = false
  }
}

function chooseType(type) {
  filters.contact_type = filters.contact_type === type ? '' : type
  loadContacts()
}

function onAvatarChange(event) {
  avatarFile.value = event.target.files?.[0] || null
}

function clearFeedback() {
  state.error = ''
  state.message = ''
}

function emptyContactForm() {
  return {
    display_name: '',
    contact_type: 'user',
    status: 'active',
    source: 'manual',
    gmail_email: '',
    email: '',
    phone: '',
    specialty: '',
    company_name: '',
    tags: '',
    internal_note: '',
  }
}

function fillForm(contact) {
  Object.assign(form, {
    display_name: contact.display_name || '',
    contact_type: contact.contact_type || 'user',
    status: contact.status || 'active',
    source: contact.source || 'manual',
    gmail_email: contact.gmail_email || '',
    email: contact.email || '',
    phone: contact.phone || '',
    specialty: contact.specialty || '',
    company_name: contact.company_name || '',
    tags: (contact.tags || []).join(', '),
    internal_note: contact.internal_note || '',
  })
}

function contactPayload() {
  return {
    display_name: form.display_name.trim(),
    contact_type: form.contact_type,
    status: form.status,
    source: form.source,
    gmail_email: form.gmail_email.trim() || null,
    email: form.email.trim() || null,
    phone: form.phone.trim() || null,
    specialty: form.specialty.trim() || null,
    company_name: form.company_name.trim() || null,
    tags: form.tags
      .split(',')
      .map((tag) => tag.trim())
      .filter(Boolean),
    internal_note: form.internal_note.trim() || null,
  }
}

function contactInitial(contact) {
  return (contact.display_name || '?').charAt(0).toUpperCase()
}

function contactIcon(type) {
  return {
    user: 'person',
    specialist: 'medical',
    seller: 'store',
    vendor: 'briefcase',
    internal: 'shield',
    lead: 'spark',
  }[type] || 'person'
}

function contactSubtitle(contact) {
  return contact.specialty || contact.company_name || contact.gmail_email || contact.email || contact.phone || 'No contact detail'
}
</script>

<template>
  <section class="contacts-workspace" aria-labelledby="contacts-module-title">
    <div v-if="view === 'cards'" class="workspace-action-row">
      <h2 id="contacts-module-title">Contact profiles</h2>
      <button class="primary-action" type="button" @click="startCreate">Create Profile</button>
    </div>

    <template v-if="view === 'cards'">
      <div class="contact-type-strip">
        <button
          v-for="item in contactCounts"
          :key="item.type"
          class="contact-type-chip"
          :class="{ 'contact-type-chip-active': filters.contact_type === item.type }"
          type="button"
          @click="chooseType(item.type)"
        >
          <span :data-icon="contactIcon(item.type)" aria-hidden="true"></span>
          {{ item.type }}
          <strong>{{ item.count }}</strong>
        </button>
      </div>

      <form class="contacts-filters contact-card-filters" @submit.prevent="loadContacts">
        <input v-model.trim="filters.search" type="search" placeholder="Search name, email, phone, company" />
        <select v-model="filters.source">
          <option value="">All sources</option>
          <option v-for="source in sources" :key="source" :value="source">{{ source }}</option>
        </select>
        <select v-model="filters.status">
          <option value="">All status</option>
          <option v-for="status in statuses" :key="status" :value="status">{{ status }}</option>
        </select>
        <button class="ghost-action" :disabled="state.loading" type="submit">Search</button>
      </form>

      <p v-if="state.error" class="form-error" role="alert">{{ state.error }}</p>
      <p v-if="state.message" class="form-success" role="status">{{ state.message }}</p>

      <div class="profile-card-grid">
        <button
          v-for="contact in state.contacts"
          :key="contact.id"
          class="profile-card"
          type="button"
          @click="openContact(contact)"
        >
          <span class="profile-avatar" :class="`profile-avatar-${contact.contact_type}`">
            <img
              v-if="avatarTypes.includes(contact.contact_type) && contact.avatar_url"
              :src="contact.avatar_url"
              alt=""
            />
            <span v-else class="profile-avatar-icon" :data-icon="contactIcon(contact.contact_type)">
              {{ contact.contact_type === 'user' ? '' : contactInitial(contact) }}
            </span>
          </span>
          <span class="profile-card-main">
            <span class="profile-name">{{ contact.display_name }}</span>
            <span class="profile-subtitle">{{ contactSubtitle(contact) }}</span>
          </span>
          <span class="profile-card-meta">
            <span class="status-soft">{{ contact.contact_type }}</span>
            <span>{{ contact.status }}</span>
          </span>
        </button>
      </div>

      <div v-if="!state.loading && state.contacts.length === 0" class="contacts-empty">
        No contacts found. Create the first profile or clear filters.
      </div>
    </template>

    <template v-else>
      <button class="back-action" type="button" @click="backToCards">
        <span aria-hidden="true">‹</span>
        Contact profiles
      </button>

      <article class="profile-detail-shell">
        <header class="profile-detail-hero">
          <span class="profile-avatar profile-avatar-large" :class="`profile-avatar-${form.contact_type}`">
            <img
              v-if="avatarTypes.includes(form.contact_type) && state.selected?.avatar_url"
              :src="state.selected.avatar_url"
              alt=""
            />
            <span v-else class="profile-avatar-icon" :data-icon="contactIcon(form.contact_type)">
              {{ form.contact_type === 'user' ? '' : contactInitial(form) }}
            </span>
          </span>

          <div>
            <p class="eyebrow">{{ form.contact_type }} profile</p>
            <h2>{{ selectedTitle }}</h2>
            <p>
              {{ form.specialty || form.company_name || form.email || form.phone || 'Profile details are ready for review.' }}
            </p>
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
            <h3>Identity</h3>
            <dl>
              <div><dt>Type</dt><dd>{{ state.selected.contact_type }}</dd></div>
              <div><dt>Status</dt><dd>{{ state.selected.status }}</dd></div>
              <div><dt>Source</dt><dd>{{ state.selected.source }}</dd></div>
              <div><dt>Company</dt><dd>{{ state.selected.company_name || 'None' }}</dd></div>
              <div><dt>Specialty</dt><dd>{{ state.selected.specialty || 'None' }}</dd></div>
            </dl>
          </div>

          <div class="profile-info-card">
            <h3>Contact</h3>
            <dl>
              <div><dt>Email</dt><dd>{{ state.selected.email || 'None' }}</dd></div>
              <div><dt>Gmail marker</dt><dd>{{ state.selected.gmail_email || 'Private / not linked' }}</dd></div>
              <div><dt>Phone</dt><dd>{{ state.selected.phone || 'None' }}</dd></div>
              <div><dt>Tags</dt><dd>{{ state.selected.tags?.join(', ') || 'None' }}</dd></div>
            </dl>
          </div>

          <div class="profile-info-card profile-info-card-wide">
            <h3>Internal note</h3>
            <p>{{ state.selected.internal_note || 'No internal summary yet.' }}</p>
          </div>
        </section>

        <form v-else class="profile-edit-form" @submit.prevent="saveContact">
          <div class="profile-form-section">
            <h3>Profile basics</h3>
            <label>
              Display name
              <input v-model.trim="form.display_name" required maxlength="120" placeholder="Full name or company" />
            </label>

            <div class="form-row">
              <label>
                Type
                <select v-model="form.contact_type" required>
                  <option v-for="type in contactTypes" :key="type" :value="type">{{ type }}</option>
                </select>
              </label>
              <label>
                Status
                <select v-model="form.status" required>
                  <option v-for="status in statuses" :key="status" :value="status">{{ status }}</option>
                </select>
              </label>
            </div>

            <div class="form-row">
              <label>
                Source
                <select v-model="form.source">
                  <option v-for="source in sources" :key="source" :value="source">{{ source }}</option>
                </select>
              </label>
              <label>
                Phone
                <input v-model.trim="form.phone" maxlength="40" placeholder="+95..." />
              </label>
            </div>
          </div>

          <div class="profile-form-section">
            <h3>Work details</h3>
            <label>
              Gmail marker
              <input v-model.trim="form.gmail_email" type="email" placeholder="realuser@gmail.com" />
            </label>
            <label>
              Primary email
              <input v-model.trim="form.email" type="email" placeholder="contact@example.com" />
            </label>

            <div class="form-row">
              <label>
                Specialty
                <input v-model.trim="form.specialty" maxlength="120" placeholder="Acne care, routine, clinic" />
              </label>
              <label>
                Company
                <input v-model.trim="form.company_name" maxlength="160" placeholder="Clinic or vendor" />
              </label>
            </div>

            <label v-if="canUploadAvatar" class="avatar-upload-field">
              Profile photo
              <input accept="image/png,image/jpeg,image/webp" type="file" @change="onAvatarChange" />
              <small>Allowed for specialists, sellers, and vendors only.</small>
            </label>
            <p v-else class="privacy-note">
              User and lead photos are hidden in admin for privacy. The user may still see their own Gmail photo in mobile.
            </p>
          </div>

          <div class="profile-form-section profile-form-section-wide">
            <h3>Admin context</h3>
            <label>
              Tags
              <input v-model.trim="form.tags" placeholder="google-user, specialist, vip" />
            </label>
            <label>
              Internal note
              <textarea v-model.trim="form.internal_note" rows="3" placeholder="Private admin summary"></textarea>
            </label>
          </div>

          <button class="primary-action" :disabled="state.saving" type="submit">
            {{ state.saving ? 'Saving...' : mode === 'edit' ? 'Save Profile' : 'Create Profile' }}
          </button>
        </form>

        <section v-if="state.selected" class="notes-panel profile-notes-panel">
          <h3>Notes</h3>
          <form class="note-form" @submit.prevent="saveNote">
            <select v-model="note.note_type">
              <option value="general">general</option>
              <option value="crm">crm</option>
              <option value="appointment">appointment</option>
              <option value="order">order</option>
              <option value="safety">safety</option>
            </select>
            <textarea v-model.trim="note.body" rows="3" placeholder="Add note for CRM, orders, scans, or safety"></textarea>
            <button class="ghost-action" :disabled="state.saving || !note.body.trim()" type="submit">Add Note</button>
          </form>

          <div class="notes-list">
            <p v-if="!state.selected.notes?.length">No notes yet.</p>
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
