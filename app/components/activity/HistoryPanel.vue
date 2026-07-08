<script setup lang="ts">
interface Props {
  showSubject?: boolean
  title?: string
}

withDefaults(defineProps<Props>(), {
  showSubject: false,
  title: '',
})

const history = useHistoryStore()

const category = ref<HistoryCategory>('all')
const period = ref<HistoryPeriod>('all')
const page = ref(1)

const totalPages = computed(() =>
  Math.max(1, Math.ceil(history.totalCount / HISTORY_PAGE_SIZE)),
)

const pageLabel = computed(() => {
  if (history.totalCount === 0) return '0 записів'
  const from = (page.value - 1) * HISTORY_PAGE_SIZE + 1
  const to = Math.min(page.value * HISTORY_PAGE_SIZE, history.totalCount)
  return `${from}–${to} з ${history.totalCount}`
})

const load = () => {
  void history.fetchPage({
    category: category.value,
    period: period.value,
    page: page.value,
  })
}

watch([category, period], () => {
  page.value = 1
  load()
})

watch(page, load)

onMounted(load)

const goPrev = () => {
  if (page.value > 1) page.value -= 1
}

const goNext = () => {
  if (page.value < totalPages.value) page.value += 1
}
</script>

<template>
  <div class="space-y-4">
    <div
      v-if="title"
      class="flex items-center justify-between gap-3 flex-wrap"
    >
      <h3 class="font-display text-lg text-cyan-100">
        {{ title }}
      </h3>
      <button
        class="btn-ghost text-xs py-2 px-3"
        :disabled="history.isLoading"
        @click="load"
      >
        Оновити
      </button>
    </div>

    <div class="space-y-3">
      <div class="flex flex-wrap gap-2">
        <button
          v-for="c in HISTORY_CATEGORIES"
          :key="c.id"
          type="button"
          class="px-3 py-1.5 rounded-lg text-xs font-medium transition-colors"
          :class="category === c.id
            ? 'bg-violet-500/20 border border-violet-400/40 text-violet-100'
            : 'glass text-slate-400 hover:text-slate-200'"
          @click="category = c.id"
        >
          {{ c.label }}
        </button>
      </div>

      <div class="flex flex-wrap gap-2">
        <button
          v-for="p in HISTORY_PERIODS"
          :key="p.id"
          type="button"
          class="px-3 py-1.5 rounded-lg text-xs font-medium transition-colors"
          :class="period === p.id
            ? 'bg-cyan-500/15 border border-cyan-400/35 text-cyan-100'
            : 'glass text-slate-500 hover:text-slate-300'"
          @click="period = p.id"
        >
          {{ p.label }}
        </button>
      </div>
    </div>

    <HistoryList
      :entries="history.items"
      :loading="history.isLoading && !history.hasLoaded"
      :error="history.error"
      :show-subject="showSubject"
    />

    <div
      v-if="history.hasLoaded && history.totalCount > 0"
      class="flex items-center justify-between gap-3 flex-wrap pt-1"
    >
      <span class="text-xs text-slate-500">{{ pageLabel }}</span>
      <div class="flex items-center gap-2">
        <BaseButton
          variant="ghost"
          :disabled="page <= 1 || history.isLoading"
          @click="goPrev"
        >
          ← Назад
        </BaseButton>
        <span class="text-xs text-slate-400 tabular-nums min-w-[4rem] text-center">
          {{ page }} / {{ totalPages }}
        </span>
        <BaseButton
          variant="ghost"
          :disabled="page >= totalPages || history.isLoading"
          @click="goNext"
        >
          Далі →
        </BaseButton>
      </div>
    </div>
  </div>
</template>
