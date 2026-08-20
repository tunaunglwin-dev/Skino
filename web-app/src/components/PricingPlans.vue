<script setup>
import scanIcon from '../assets/branding/skino_icon_scan.png'
import progressIcon from '../assets/branding/skino_icon_progress.webp'
import specialistIcon from '../assets/branding/skino_icon_specialist.png'

defineProps({ compact: { type: Boolean, default: false } })
defineEmits(['choose'])

const plans = [
  {
    key: 'starter',
    name: 'Starter',
    billing: 'Free plan',
    description: 'Try one guided face scan after creating your account.',
    features: ['1 introductory face scan', 'Core skin summary', 'Simple care guidance'],
    action: 'Included in demo',
    icon: scanIcon,
    tone: '#6aa92f',
    tint: '#f4f8e9',
  },
  {
    key: 'flex',
    name: 'Flex',
    billing: 'Pay as you go',
    description: 'Purchase additional scans only when you need a fresh check-in.',
    features: ['No subscription', 'Full scan result', 'Routine and history access'],
    action: 'Coming after demo',
    icon: progressIcon,
    tone: '#f36a16',
    tint: '#fff3e8',
    featured: true,
  },
  {
    key: 'glow-plus',
    name: 'Glow+',
    billing: 'Premium plan',
    description: 'Ongoing tracking and deeper guidance for regular Skino users.',
    features: ['Unlimited scans', 'Advanced progress insights', 'Priority features'],
    action: 'Coming after demo',
    icon: specialistIcon,
    tone: '#7c65b5',
    tint: '#f5f0ff',
  },
]
</script>

<template>
  <div class="grid gap-3 md:grid-cols-3" :class="compact ? 'text-left' : ''">
    <article
      v-for="plan in plans"
      :key="plan.key"
      class="group relative grid overflow-hidden rounded-[24px] border bg-white transition duration-200 hover:-translate-y-1 hover:shadow-[0_18px_44px_rgba(62,42,30,.10)]"
      :class="[compact ? 'min-h-[310px] p-4' : 'min-h-[390px] p-5 sm:p-6', plan.featured ? 'border-skino-line-orange shadow-skino-sm' : 'border-skino-line']"
    >
      <span v-if="plan.featured" class="absolute right-4 top-4 rounded-full bg-skino-orange px-2.5 py-1 text-[9px] text-white">Most flexible</span>
      <div class="grid content-start gap-4">
        <span class="grid size-20 place-items-center rounded-2xl" :style="{ backgroundColor: plan.tint }"><img class="size-16 object-contain" :src="plan.icon" alt="" /></span>
        <div>
          <span class="inline-flex rounded-full px-3 py-1 text-[10px] font-medium" :style="{ color: plan.tone, backgroundColor: plan.tint }">{{ plan.name }}</span>
          <h3 class="mb-1 mt-3 text-xl font-medium tracking-[-.03em] text-skino-ink">{{ plan.billing }}</h3>
          <p class="mb-0 text-[11px] leading-5 text-skino-muted">{{ plan.description }}</p>
        </div>
        <ul class="grid gap-2 p-0 text-[11px] text-skino-muted">
          <li v-for="feature in plan.features" :key="feature" class="flex items-center gap-2"><span class="grid size-5 shrink-0 place-items-center rounded-full text-[9px] text-white" :style="{ backgroundColor: plan.tone }">✓</span>{{ feature }}</li>
        </ul>
      </div>
      <button class="mt-5 min-h-11 self-end rounded-xl border px-4 text-xs font-medium" :style="{ borderColor: plan.tone, color: plan.featured ? '#fff' : plan.tone, backgroundColor: plan.featured ? plan.tone : plan.tint }" type="button" disabled>{{ plan.action }}</button>
    </article>
  </div>
</template>
