<script setup>
import { computed, reactive } from 'vue'
import BrandMark from './BrandMark.vue'

defineProps({
  loading: {
    type: Boolean,
    required: true,
  },
  error: {
    type: String,
    default: '',
  },
  message: {
    type: String,
    default: '',
  },
})

const emit = defineEmits(['request-reset', 'reset-password', 'back-to-login'])
const params = new URLSearchParams(window.location.search)
const hasToken = computed(() => Boolean(form.token))

const form = reactive({
  email: params.get('email') || '',
  token: params.get('token') || '',
  password: '',
  password_confirmation: '',
})

if (params.has('token') || params.has('email')) {
  window.history.replaceState({}, '', '/reset-password')
}
</script>

<template>
  <section class="login-screen">
    <div class="login-panel">
      <div class="login-copy">
        <p class="eyebrow">Skino Admin Recovery</p>
        <h1>{{ hasToken ? 'Create a new admin password.' : 'Reset your Skino admin password.' }}</h1>
        <p>
          {{ hasToken ? 'Enter a strong replacement password to continue.' : 'Request a secure reset link for your admin account.' }}
        </p>
      </div>

      <form
        class="login-card"
        @submit.prevent="hasToken ? emit('reset-password', form) : emit('request-reset', form.email)"
      >
        <div class="form-heading">
          <BrandMark />
          <div>
            <h2>Admin Password Reset</h2>
            <p>{{ hasToken ? 'Complete the reset request.' : 'Send a reset email.' }}</p>
          </div>
        </div>

        <label for="reset-email">
          Email
          <input
            id="reset-email"
            v-model.trim="form.email"
            autocomplete="email"
            inputmode="email"
            required
            type="email"
            placeholder="admin@example.com"
          />
        </label>

        <template v-if="hasToken">
          <label for="reset-password">
            New password
            <input
              id="reset-password"
              v-model="form.password"
              autocomplete="new-password"
              required
              type="password"
              placeholder="New password"
            />
          </label>

          <label for="reset-password-confirmation">
            Confirm password
            <input
              id="reset-password-confirmation"
              v-model="form.password_confirmation"
              autocomplete="new-password"
              required
              type="password"
              placeholder="Confirm password"
            />
          </label>
        </template>

        <p v-if="error" class="form-error" role="alert">{{ error }}</p>
        <p v-if="message" class="form-success" role="status">{{ message }}</p>

        <button class="primary-action" :disabled="loading" type="submit">
          {{ loading ? 'Working...' : hasToken ? 'Reset password' : 'Send reset link' }}
        </button>

        <button class="link-action" type="button" @click="emit('back-to-login')">
          Back to login
        </button>
      </form>
    </div>
  </section>
</template>
