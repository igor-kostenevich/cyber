<script setup lang="ts">
import { PROFESSIONS } from '~/composables/useProfessions'

interface Props {
  profileId: string
  compact?: boolean
  editable?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  compact: false,
  editable: false,
})

const twins = useTwinsStore()
const open = ref(false)
const updatingId = ref<string | null>(null)

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

const onProfessionChange = async (twinId: string, val: string) => {
  updatingId.value = twinId
  try {
    await twins.adminUpdateTwinProfession(twinId, val ? Number(val) : null, props.profileId)
  }
  catch {
  }
  finally {
    updatingId.value = null
  }
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
      <div
        v-for="t in items"
        :key="t.id"
        class="inline-flex items-center gap-1 rounded border border-slate-600/35 bg-slate-900/40 px-1.5 py-0.5 text-[11px] text-slate-400"
      >
        <ProfessionIcon :profession="t.profession" size="xs" />
        <span>{{ t.nickname }}</span>
        <select
          v-if="editable"
          class="ml-1 bg-transparent text-[10px] text-slate-400 outline-none cursor-pointer hover:text-slate-200 transition-colors border border-slate-600/30 rounded px-1"
          :value="t.profession ?? ''"
          :disabled="updatingId === t.id"
          @change="onProfessionChange(t.id, ($event.target as HTMLSelectElement).value)"
        >
          <option value="">— клас —</option>
          <option
            v-for="prof in PROFESSIONS"
            :key="prof.id"
            :value="prof.id"
          >
            {{ prof.name }}
          </option>
        </select>
      </div>
    </div>
  </div>
</template>
