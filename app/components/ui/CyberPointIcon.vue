<script setup lang="ts">
interface Props {
  size?: 'xs' | 'sm' | 'md' | 'lg'
}

const props = withDefaults(defineProps<Props>(), {
  size: 'sm',
})

const uid = useId()
const strokeId = `cp-s-${uid}`
const fillId = `cp-f-${uid}`
const glowId = `cp-g-${uid}`

const sizeClass = computed(() => {
  switch (props.size) {
    case 'xs': return 'h-3 w-3'
    case 'md': return 'h-5 w-5'
    case 'lg': return 'h-6 w-6'
    default: return 'h-4 w-4'
  }
})
</script>

<template>
  <svg
    viewBox="0 0 24 24"
    fill="none"
    xmlns="http://www.w3.org/2000/svg"
    aria-hidden="true"
    :class="[sizeClass, 'shrink-0 drop-shadow-[0_0_6px_rgba(34,211,238,0.45)]', $attrs.class]"
  >
    <path
      d="M12 2.5L19.5 7v10L12 21.5 4.5 17V7L12 2.5Z"
      :stroke="`url(#${strokeId})`"
      stroke-width="1.5"
      :fill="`url(#${fillId})`"
    />
    <path
      d="M9.5 8.5h3.2c1.5 0 2.4.8 2.4 2s-.9 2-2.4 2H11v2.8"
      stroke="#e0f2fe"
      stroke-width="1.6"
      stroke-linecap="round"
      stroke-linejoin="round"
    />
    <circle
      cx="12"
      cy="12"
      r="9"
      :stroke="`url(#${glowId})`"
      stroke-width="0.75"
      opacity="0.35"
    />
    <defs>
      <linearGradient
        :id="strokeId"
        x1="4"
        y1="3"
        x2="20"
        y2="21"
      >
        <stop stop-color="#22d3ee" />
        <stop
          offset="1"
          stop-color="#a78bfa"
        />
      </linearGradient>
      <linearGradient
        :id="fillId"
        x1="6"
        y1="4"
        x2="18"
        y2="20"
      >
        <stop stop-color="#0f172a" />
        <stop
          offset="1"
          stop-color="#1e1b4b"
        />
      </linearGradient>
      <linearGradient
        :id="glowId"
        x1="3"
        y1="12"
        x2="21"
        y2="12"
      >
        <stop stop-color="#22d3ee" />
        <stop
          offset="1"
          stop-color="#c084fc"
        />
      </linearGradient>
    </defs>
  </svg>
</template>
