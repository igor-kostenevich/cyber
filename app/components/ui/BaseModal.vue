<script setup lang="ts">
interface Props {
  open: boolean
  title?: string
  description?: string
  size?: 'sm' | 'md' | 'lg' | 'xl'
  closeOnBackdrop?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  size: 'md',
  closeOnBackdrop: true,
})

const emit = defineEmits<{
  'update:open': [value: boolean]
  close: []
}>()

const sizeClass = computed(() => {
  switch (props.size) {
    case 'sm':
      return 'max-w-md'
    case 'lg':
      return 'max-w-2xl'
    case 'xl':
      return 'max-w-4xl'
    default:
      return 'max-w-lg'
  }
})

const onBackdrop = () => {
  if (!props.closeOnBackdrop) return
  emit('update:open', false)
  emit('close')
}

const onClose = () => {
  emit('update:open', false)
  emit('close')
}

const onKeydown = (e: KeyboardEvent) => {
  if (e.key === 'Escape' && props.open) onClose()
}

onMounted(() => {
  document.addEventListener('keydown', onKeydown)
})

onBeforeUnmount(() => {
  document.removeEventListener('keydown', onKeydown)
})

watch(
  () => props.open,
  (open) => {
    if (typeof document === 'undefined') return
    document.body.style.overflow = open ? 'hidden' : ''
  },
)
</script>

<template>
  <Teleport to="body">
    <Transition
      enter-active-class="transition duration-200 ease-out"
      enter-from-class="opacity-0"
      enter-to-class="opacity-100"
      leave-active-class="transition duration-150 ease-in"
      leave-from-class="opacity-100"
      leave-to-class="opacity-0"
    >
      <div
        v-if="open"
        class="fixed inset-0 z-50 grid place-items-center p-4"
      >
        <div
          class="absolute inset-0 bg-ink-900/80 backdrop-blur-sm"
          @click="onBackdrop"
        />

        <Transition
          enter-active-class="transition duration-200 ease-out"
          enter-from-class="opacity-0 translate-y-2 scale-[0.98]"
          enter-to-class="opacity-100 translate-y-0 scale-100"
          leave-active-class="transition duration-150 ease-in"
          leave-from-class="opacity-100 scale-100"
          leave-to-class="opacity-0 scale-[0.98]"
        >
          <div
            v-if="open"
            class="relative z-10 w-full glass-strong rounded-2xl shadow-glow overflow-hidden"
            :class="sizeClass"
          >
            <div
              class="pointer-events-none absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-cyan-400/60 to-transparent"
            />

            <header
              v-if="title || $slots.header"
              class="flex items-start justify-between gap-4 p-5 md:p-6 border-b border-white/10"
            >
              <div class="flex-1 min-w-0">
                <slot name="header">
                  <h3 class="font-display text-lg md:text-xl text-gradient-cyber">
                    {{ title }}
                  </h3>
                  <p
                    v-if="description"
                    class="mt-1 text-sm text-slate-400"
                  >
                    {{ description }}
                  </p>
                </slot>
              </div>
              <button
                class="rounded-lg p-1.5 text-slate-400 hover:text-cyan-300 hover:bg-white/5 transition-colors"
                aria-label="Закрити"
                @click="onClose"
              >
                <svg
                  width="18"
                  height="18"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <line
                    x1="18"
                    y1="6"
                    x2="6"
                    y2="18"
                  />
                  <line
                    x1="6"
                    y1="6"
                    x2="18"
                    y2="18"
                  />
                </svg>
              </button>
            </header>

            <div class="p-5 md:p-6">
              <slot />
            </div>

            <footer
              v-if="$slots.footer"
              class="flex items-center justify-end gap-2 p-5 md:p-6 border-t border-white/10 bg-white/[0.02]"
            >
              <slot name="footer" />
            </footer>
          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>
