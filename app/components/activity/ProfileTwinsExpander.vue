<script setup lang="ts">
interface Props {
  profileId: string
  compact?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  compact: false,
})

const twins = useTwinsStore()
const open = ref(false)

const items = computed(() => twins.getForProfile(props.profileId))

onMounted(async () => {
  if (items.value.length === 0) {
    try {
      await twins.fetchForProfiles([props.profileId])
    }
    catch {
    }
  }
})

const toggle = () => {
  open.value = !open.value
}
</script>

<template>
  <div
    v-if="items.length > 0"
    class="mt-1"
  >
    <button
      type="button"
      class="inline-flex items-center gap-1 text-[11px] text-slate-500 hover:text-slate-300 transition-colors"
      @click="toggle"
    >
      <span class="opacity-70">👥</span>
      <span>Твінки ({{ items.length }})</span>
      <span class="text-[10px]">{{ open ? '▲' : '▼' }}</span>
    </button>

    <div
      v-if="open"
      class="mt-1.5 flex flex-wrap gap-1.5"
      :class="compact ? '' : 'pl-1'"
    >
      <span
        v-for="t in items"
        :key="t.id"
        class="inline-flex items-center gap-1 rounded border border-slate-600/35 bg-slate-900/40 px-1.5 py-0.5 text-[11px] text-slate-400"
      >
        <span class="opacity-50">◦</span>
        <span>{{ t.nickname }}</span>
      </span>
    </div>
  </div>
</template>
