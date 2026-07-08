<script setup lang="ts">
interface Props {
  variant?: 'primary' | 'ghost' | 'danger' | 'success' | 'warn'
  type?: 'button' | 'submit' | 'reset'
  loading?: boolean
  disabled?: boolean
  fullWidth?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  variant: 'primary',
  type: 'button',
  loading: false,
  disabled: false,
  fullWidth: false,
})

defineEmits<{
  click: [event: MouseEvent]
}>()

const variantClass = computed(() => {
  switch (props.variant) {
    case 'ghost':
      return 'btn-ghost'
    case 'danger':
      return 'btn-danger'
    case 'success':
      return 'btn-success'
    case 'warn':
      return 'btn-warn'
    default:
      return 'btn-primary'
  }
})
</script>

<template>
  <button
    :type="type"
    :disabled="disabled || loading"
    :class="[variantClass, fullWidth ? 'w-full' : '']"
    @click="(e) => $emit('click', e)"
  >
    <span
      v-if="loading"
      class="inline-block h-4 w-4 rounded-full border-2 border-white/40 border-t-white animate-spin"
    />
    <slot />
  </button>
</template>
