<script setup lang="ts">
interface Props {
  value?: number | string | null
  showWord?: boolean
  sign?: '+' | '−' | '-'
  iconSize?: 'xs' | 'sm' | 'md' | 'lg'
  muted?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  value: undefined,
  showWord: false,
  sign: undefined,
  iconSize: 'sm',
  muted: false,
})

const { formatPoints, cyberPointsWord } = useFormatPoints()

const displayValue = computed(() => {
  if (props.value == null || props.value === '') return null
  const num = typeof props.value === 'number' ? props.value : Number.parseFloat(String(props.value))
  if (Number.isNaN(num)) return String(props.value)
  return formatPoints(num)
})

const word = computed(() => {
  if (displayValue.value == null) return ''
  const num = typeof props.value === 'number' ? props.value : Number.parseFloat(String(props.value))
  return Number.isNaN(num) ? 'Cyber-кредитів' : cyberPointsWord(num)
})
</script>

<template>
  <span
    class="inline-flex items-center gap-1 tabular-nums"
    :class="[muted ? 'text-slate-400' : '', $attrs.class]"
  >
    <CyberPointIcon :size="iconSize" />
    <span v-if="displayValue != null">
      <span v-if="sign">{{ sign }}</span>{{ displayValue }}
      <span
        v-if="showWord"
        class="ml-0.5"
      >{{ word }}</span>
    </span>
    <slot v-else />
  </span>
</template>
