<script setup lang="ts" generic="T extends string | number">
interface Option {
  value: T
  label: string
  disabled?: boolean
}

interface Props {
  options: Option[]
  placeholder?: string
  disabled?: boolean
  size?: 'sm' | 'md'
}

const props = withDefaults(defineProps<Props>(), {
  placeholder: undefined,
  disabled: false,
  size: 'md',
})

const model = defineModel<T>()

const isOpen = ref(false)
const triggerRef = ref<HTMLButtonElement | null>(null)

const dropdownStyle = ref<{ top: string, left: string, width: string }>({
  top: '0px',
  left: '0px',
  width: '0px',
})

const selectedLabel = computed(() => {
  const found = props.options.find((o) => o.value === model.value)
  return found?.label ?? props.placeholder ?? '—'
})

const hasValue = computed(
  () => model.value !== undefined && model.value !== null && model.value !== ('' as T),
)

function updatePosition() {
  if (!triggerRef.value) return
  const rect = triggerRef.value.getBoundingClientRect()
  dropdownStyle.value = {
    top: `${rect.bottom + window.scrollY + 4}px`,
    left: `${rect.left + window.scrollX}px`,
    width: `${rect.width}px`,
  }
}

function open() {
  if (props.disabled) return
  updatePosition()
  isOpen.value = true
}

function toggle() {
  if (isOpen.value) {
    isOpen.value = false
  }
  else {
    open()
  }
}

function select(value: T) {
  model.value = value
  isOpen.value = false
}

function onDocClick(e: MouseEvent) {
  if (triggerRef.value && triggerRef.value.contains(e.target as Node)) return
  isOpen.value = false
}

onMounted(() => document.addEventListener('click', onDocClick, true))
onBeforeUnmount(() => document.removeEventListener('click', onDocClick, true))
</script>

<template>
  <div class="relative">
    <button
      ref="triggerRef"
      type="button"
      :disabled="disabled"
      class="w-full flex items-center justify-between gap-2 rounded-xl bg-ink-800/70 border border-white/10
        text-slate-100 outline-none transition-all
        hover:border-cyan-400/30 focus:border-cyan-400/50 focus:ring-2 focus:ring-cyan-400/20
        disabled:opacity-50 disabled:cursor-not-allowed"
      :class="size === 'sm' ? 'px-2.5 py-1.5 text-sm' : 'px-3 py-2.5 text-sm'"
      @click="toggle"
    >
      <span :class="hasValue ? 'text-slate-100' : 'text-slate-500'">
        {{ selectedLabel }}
      </span>
      <svg
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 20 20"
        fill="currentColor"
        class="h-4 w-4 text-slate-400 shrink-0 transition-transform duration-150"
        :class="isOpen ? 'rotate-180' : ''"
      >
        <path
          fill-rule="evenodd"
          d="M5.22 8.22a.75.75 0 0 1 1.06 0L10 11.94l3.72-3.72a.75.75 0 1 1 1.06 1.06l-4.25 4.25a.75.75 0 0 1-1.06 0L5.22 9.28a.75.75 0 0 1 0-1.06Z"
          clip-rule="evenodd"
        />
      </svg>
    </button>

    <Teleport to="body">
      <Transition
        enter-active-class="transition-all duration-150 origin-top"
        enter-from-class="opacity-0 scale-y-95"
        enter-to-class="opacity-100 scale-y-100"
        leave-active-class="transition-all duration-100 origin-top"
        leave-from-class="opacity-100 scale-y-100"
        leave-to-class="opacity-0 scale-y-95"
      >
        <ul
          v-if="isOpen"
          class="fixed z-[9999] rounded-xl bg-ink-900 border border-white/10 shadow-xl overflow-hidden py-1"
          :style="dropdownStyle"
        >
          <li
            v-if="placeholder && !hasValue"
            class="px-3 py-2 text-sm text-slate-500 cursor-default"
          >
            {{ placeholder }}
          </li>
          <li
            v-for="option in options"
            :key="option.value"
            class="px-3 py-2 text-sm cursor-pointer transition-colors"
            :class="[
              option.value === model ? 'text-cyan-300 bg-cyan-500/10' : 'text-slate-200 hover:bg-white/5',
              option.disabled ? 'opacity-40 cursor-not-allowed pointer-events-none' : '',
            ]"
            @click="!option.disabled && select(option.value)"
          >
            {{ option.label }}
          </li>
        </ul>
      </Transition>
    </Teleport>
  </div>
</template>
