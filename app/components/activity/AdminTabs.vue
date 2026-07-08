<script setup lang="ts">
import type { TabItem } from '~/types/activity'

interface Props {
  tabs: TabItem[]
  modelValue: string
}

defineProps<Props>()
const emit = defineEmits<{ 'update:modelValue': [value: string] }>()
</script>

<template>
  <nav class="flex items-center gap-2 flex-wrap">
    <button
      v-for="tab in tabs"
      :key="tab.id"
      class="px-4 py-2 rounded-xl text-sm font-medium transition-colors flex items-center gap-2"
      :class="modelValue === tab.id
        ? 'bg-gradient-to-r from-cyan-500/25 to-blue-500/25 border border-cyan-400/40 text-cyan-100 shadow-glow-sm'
        : 'glass text-slate-300 hover:text-cyan-100 hover:border-cyan-300/30'"
      @click="emit('update:modelValue', tab.id)"
    >
      {{ tab.label }}
      <span
        v-if="tab.badge && tab.badge > 0"
        class="badge-info text-[10px] px-2 py-0"
      >
        {{ tab.badge }}
      </span>
    </button>
  </nav>
</template>
