<script setup lang="ts">
import type { Profile } from '~/types/activity'

interface Props {
  players: Profile[]
  modelValue: string[]
}

const props = defineProps<Props>()
const emit = defineEmits<{ 'update:modelValue': [value: string[]] }>()

const search = ref('')

const filtered = computed(() => {
  const q = search.value.trim().toLowerCase()
  if (!q) return props.players
  return props.players.filter(
    (p) =>
      p.nickname.toLowerCase().includes(q)
      || (p.display_name ?? '').toLowerCase().includes(q),
  )
})

const selectedSet = computed(() => new Set(props.modelValue))

const toggle = (id: string) => {
  const next = new Set(props.modelValue)
  if (next.has(id)) next.delete(id)
  else next.add(id)
  emit('update:modelValue', [...next])
}

const selectAll = () => {
  emit('update:modelValue', filtered.value.map((p) => p.id))
}

const clearAll = () => {
  emit('update:modelValue', [])
}
</script>

<template>
  <div class="space-y-3">
    <div class="flex items-center gap-2">
      <input
        v-model="search"
        type="text"
        class="input flex-1"
        placeholder="Пошук гравця…"
      >
      <button
        type="button"
        class="btn-ghost text-xs py-2 px-3 whitespace-nowrap"
        @click="selectAll"
      >
        Усі
      </button>
      <button
        type="button"
        class="btn-ghost text-xs py-2 px-3 whitespace-nowrap"
        @click="clearAll"
      >
        Скинути
      </button>
    </div>

    <div class="text-xs text-slate-500">
      Обрано: {{ modelValue.length }} з {{ players.length }}
    </div>

    <EmptyState
      v-if="players.length === 0"
      title="Немає підтверджених гравців"
      description="Спочатку підтвердіть гравців у розділі «Гравці»."
    />

    <ul
      v-else
      class="max-h-72 overflow-y-auto space-y-1 pr-1"
    >
      <li
        v-for="p in filtered"
        :key="p.id"
      >
        <label
          class="flex items-start gap-3 rounded-lg px-3 py-2 cursor-pointer transition-colors"
          :class="selectedSet.has(p.id)
            ? 'bg-cyan-500/15 border border-cyan-400/30'
            : 'glass hover:bg-white/[0.06]'"
        >
          <input
            type="checkbox"
            class="h-4 w-4 accent-cyan-400 mt-0.5 shrink-0"
            :checked="selectedSet.has(p.id)"
            @change="toggle(p.id)"
          >
          <div class="flex-1 min-w-0">
            <div class="flex items-center gap-2 flex-wrap">
              <span class="text-sm text-slate-100 truncate">{{ p.nickname }}</span>
              <span
                v-if="p.display_name"
                class="text-xs text-slate-500 truncate"
              >({{ p.display_name }})</span>
            </div>
            <ProfileTwinsExpander
              :profile-id="p.id"
              compact
            />
          </div>
          <span class="text-xs text-slate-500 shrink-0 mt-0.5">
            <CyberPoints
              :value="p.points_balance"
              icon-size="xs"
              muted
            />
          </span>
        </label>
      </li>
    </ul>
  </div>
</template>
