<script setup lang="ts">
interface Props {
  tone?: 'default' | 'violet' | 'pink'
  padded?: boolean
  interactive?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  tone: 'default',
  padded: true,
  interactive: false,
})

const toneClass = computed(() => {
  switch (props.tone) {
    case 'violet':
      return 'shadow-glow-violet'
    case 'pink':
      return 'shadow-glow-pink'
    default:
      return 'shadow-glow-sm'
  }
})
</script>

<template>
  <div
    class="card-cyber relative overflow-hidden"
    :class="[
      toneClass,
      padded ? 'p-5 md:p-6' : '',
      interactive ? 'hover:-translate-y-0.5 transition-transform' : '',
    ]"
  >
    <div
      class="pointer-events-none absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-cyan-400/50 to-transparent"
    />
    <slot />
  </div>
</template>
