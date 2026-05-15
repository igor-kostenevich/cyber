<script setup lang="ts">
interface Props {
  title?: string
  description?: string
  tone?: 'default' | 'error'
}

withDefaults(defineProps<Props>(), {
  title: 'Поки порожньо',
  description: '',
  tone: 'default',
})
</script>

<template>
  <div
    class="card-cyber p-8 text-center"
    :class="tone === 'error' ? 'border-rose-400/30 shadow-glow-pink' : ''"
  >
    <div
      class="mx-auto h-12 w-12 rounded-full grid place-items-center mb-3"
      :class="tone === 'error' ? 'bg-rose-500/15 border border-rose-400/30' : 'bg-cyan-500/10 border border-cyan-400/30'"
    >
      <svg
        v-if="tone === 'error'"
        width="22"
        height="22"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
        class="text-rose-300"
      >
        <circle
          cx="12"
          cy="12"
          r="10"
        />
        <line
          x1="12"
          y1="8"
          x2="12"
          y2="12"
        />
        <line
          x1="12"
          y1="16"
          x2="12.01"
          y2="16"
        />
      </svg>
      <svg
        v-else
        width="22"
        height="22"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        stroke-width="2"
        class="text-cyan-300"
      >
        <circle
          cx="12"
          cy="12"
          r="10"
        />
        <line
          x1="12"
          y1="16"
          x2="12"
          y2="12"
        />
        <line
          x1="12"
          y1="8"
          x2="12.01"
          y2="8"
        />
      </svg>
    </div>
    <h3
      class="font-display text-base font-bold"
      :class="tone === 'error' ? 'text-rose-200' : 'text-slate-200'"
    >
      {{ title }}
    </h3>
    <p
      v-if="description"
      class="mt-1 text-sm text-slate-400 max-w-md mx-auto"
    >
      {{ description }}
    </p>
    <div
      v-if="$slots.actions"
      class="mt-4 flex items-center justify-center gap-2"
    >
      <slot name="actions" />
    </div>
  </div>
</template>
