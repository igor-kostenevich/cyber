<script setup lang="ts">
interface Props {
  width?: string
  height?: string
  rounded?: string
}

withDefaults(defineProps<Props>(), {
  width: '100%',
  height: '0.75rem',
  rounded: 'rounded-md',
})
</script>

<template>
  <div
    :class="['animate-pulse bg-white/[0.06]', rounded]"
    :style="{ width, height }"
  />
</template>
