<script setup>
import { reactive } from 'vue'
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
})

const emit = defineEmits(['login', 'forgot-password'])

const form = reactive({
  email: '',
  password: '',
})
</script>

<template>
  <section class="login-screen">
    <div class="login-panel">
      <div class="login-copy">
        <p class="eyebrow">Skino Admin</p>
        <h1>Manage scans, routines, users, and specialist care.</h1>
        <p>Secure access for Contacts, appointment CRM, care routine progress, scan review, and AI training governance.</p>
      </div>

      <form class="login-card" @submit.prevent="emit('login', form)">
        <div class="form-heading">
          <BrandMark />
          <div>
            <h2>Skino Admin Login</h2>
            <p>Use your authorized admin account.</p>
          </div>
        </div>

        <label for="email">
          Email
          <input
            id="email"
            v-model.trim="form.email"
            autocomplete="email"
            inputmode="email"
            required
            type="email"
            placeholder="admin@example.com"
          />
        </label>

        <label for="password">
          Password
          <input
            id="password"
            v-model="form.password"
            autocomplete="current-password"
            required
            type="password"
            placeholder="Enter password"
          />
        </label>

        <p v-if="error" class="form-error" role="alert">{{ error }}</p>

        <button class="primary-action" :disabled="loading" type="submit">
          {{ loading ? 'Signing in...' : 'Login' }}
        </button>

        <button class="link-action" type="button" @click="emit('forgot-password')">
          Forgot password?
        </button>
      </form>
    </div>
  </section>
</template>
