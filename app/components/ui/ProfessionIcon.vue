<script setup lang="ts">
import { getProfession } from '~/composables/useProfessions'

interface Props {
  profession: number | null | undefined
  size?: 'xs' | 'sm' | 'md'
}

const props = withDefaults(defineProps<Props>(), {
  size: 'sm',
})

const prof = computed(() => getProfession(props.profession))

const sizeClass = computed(() => {
  switch (props.size) {
    case 'xs': return 'h-3.5 w-3.5'
    case 'md': return 'h-6 w-6'
    default: return 'h-4 w-4'
  }
})
</script>

<template>
  <img
    v-if="prof"
    :src="prof.icon"
    :alt="prof.name"
    :title="prof.name"
    :class="[sizeClass, 'object-contain shrink-0 inline-block']"
  >
</template>
