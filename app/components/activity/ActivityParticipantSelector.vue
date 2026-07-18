<script setup lang="ts">
import type { ActivityAwardParticipant, ActivityType, Profile } from '~/types/activity'

interface Props {
  players: Profile[]
  activityType: ActivityType
  modelValue: ActivityAwardParticipant[]
}

const props = defineProps<Props>()
const emit = defineEmits<{ 'update:modelValue': [value: ActivityAwardParticipant[]] }>()

const twins = useTwinsStore()
const settings = useActivitySettingsStore()
const { calculateParticipantPoints } = useActivityAward()

const search = ref('')

const twinBonusEnabled = computed(() => settings.getTwinBonusEnabled(props.activityType))

const filtered = computed(() => {
  const q = search.value.trim().toLowerCase()
  if (!q) return props.players
  return props.players.filter(
    (p) =>
      p.nickname.toLowerCase().includes(q)
      || (p.display_name ?? '').toLowerCase().includes(q)
      || twins.getForProfile(p.id).some((t) => t.nickname.toLowerCase().includes(q)),
  )
})

const selectedMap = computed(() => {
  const map = new Map<string, ActivityAwardParticipant>()
  for (const item of props.modelValue) map.set(item.profileId, item)
  return map
})

watch(
  () => props.players.map((p) => p.id),
  async (ids) => {
    if (ids.length === 0) return
    try {
      await twins.fetchForProfiles(ids)
    }
    catch {
    }
  },
  { immediate: true },
)

const isSelected = (profileId: string) => selectedMap.value.has(profileId)

const emitSelection = (next: ActivityAwardParticipant[]) => {
  emit('update:modelValue', next)
}

const togglePlayer = (profileId: string) => {
  const next = [...props.modelValue]
  const idx = next.findIndex((p) => p.profileId === profileId)
  if (idx >= 0) {
    next.splice(idx, 1)
  }
  else {
    next.push({ profileId, includeMain: true, twinIds: [] })
  }
  emitSelection(next)
}

const updateParticipant = (profileId: string, patch: Partial<ActivityAwardParticipant>) => {
  emitSelection(
    props.modelValue.map((p) =>
      p.profileId === profileId ? { ...p, ...patch } : p,
    ),
  )
}

const toggleMain = (profileId: string) => {
  const current = selectedMap.value.get(profileId)
  if (!current) return
  updateParticipant(profileId, { includeMain: !current.includeMain })
}

const toggleTwin = (profileId: string, twinId: string) => {
  const current = selectedMap.value.get(profileId)
  if (!current) return

  const set = new Set(current.twinIds)
  if (set.has(twinId)) set.delete(twinId)
  else set.add(twinId)

  updateParticipant(profileId, { twinIds: [...set] })
}

const isTwinSelected = (profileId: string, twinId: string) =>
  selectedMap.value.get(profileId)?.twinIds.includes(twinId) ?? false

const chipClass = (active: boolean) =>
  active
    ? 'border-cyan-400/50 bg-cyan-500/20 text-cyan-100'
    : 'border-slate-600/40 bg-slate-800/40 text-slate-400 hover:border-slate-500/60 hover:text-slate-200'

const previewFor = (participant: ActivityAwardParticipant, basePoints: number) =>
  calculateParticipantPoints(basePoints, participant)

const selectAll = () => {
  emitSelection(
    filtered.value.map((p) => ({
      profileId: p.id,
      includeMain: true,
      twinIds: [],
    })),
  )
}

const clearAll = () => emitSelection([])
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
      <span v-if="twinBonusEnabled"> · клікайте твінків для +20% кожен</span>
    </div>

    <EmptyState
      v-if="players.length === 0"
      title="Немає підтверджених гравців"
      description="Спочатку підтвердіть гравців у розділі «Гравці»."
    />

    <ul
      v-else
      class="max-h-80 overflow-y-auto space-y-2 pr-1"
    >
      <li
        v-for="p in filtered"
        :key="p.id"
        class="rounded-xl px-3 py-2 transition-colors"
        :class="isSelected(p.id)
          ? 'bg-cyan-500/10 border border-cyan-400/25'
          : 'glass'"
      >
        <div class="flex items-start gap-3">
          <input
            type="checkbox"
            class="h-4 w-4 accent-cyan-400 mt-1 shrink-0"
            :checked="isSelected(p.id)"
            @change="togglePlayer(p.id)"
          >

          <div class="flex-1 min-w-0 space-y-2">
            <div class="flex items-center justify-between gap-2">
              <div class="min-w-0">
                <div class="flex items-center gap-2 flex-wrap">
                  <ProfessionIcon :profession="p.profession" size="xs" />
                  <span class="text-sm text-slate-100">{{ p.nickname }}</span>
                  <span
                    v-if="p.display_name"
                    class="text-xs text-slate-500"
                  >({{ p.display_name }})</span>
                </div>
              </div>
              <span class="text-xs text-slate-500 shrink-0">
                <CyberPoints
                  :value="p.points_balance"
                  icon-size="xs"
                  muted
                />
              </span>
            </div>

            <div
              v-if="isSelected(p.id) && selectedMap.get(p.id)"
              class="space-y-2"
            >
              <div class="flex flex-wrap gap-1.5 items-center">
                <span class="text-[10px] text-slate-500 uppercase tracking-wide mr-1">Участь:</span>

                <button
                  type="button"
                  class="inline-flex items-center gap-1 rounded-md border px-2 py-0.5 text-[11px] transition-colors"
                  :class="chipClass(selectedMap.get(p.id)!.includeMain)"
                  @click="toggleMain(p.id)"
                >
                  <span class="opacity-60">★</span>
                  Основний
                </button>

                <button
                  v-for="t in twins.getForProfile(p.id)"
                  :key="t.id"
                  type="button"
                  class="inline-flex items-center gap-1 rounded-md border px-2 py-0.5 text-[11px] transition-colors"
                  :class="chipClass(isTwinSelected(p.id, t.id))"
                  @click="toggleTwin(p.id, t.id)"
                >
                  <ProfessionIcon :profession="t.profession" size="xs" />
                  {{ t.nickname }}
                </button>

                <span
                  v-if="twins.getForProfile(p.id).length === 0"
                  class="text-[11px] text-slate-500"
                >
                  немає твінків
                </span>
              </div>

              <p
                v-if="!selectedMap.get(p.id)!.includeMain && selectedMap.get(p.id)!.twinIds.length === 0"
                class="text-[11px] text-amber-300"
              >
                Оберіть основного або хоча б одного твінка
              </p>
            </div>

            <ProfileTwinsExpander
              v-else-if="twins.getForProfile(p.id).length > 0"
              :profile-id="p.id"
              compact
            />
          </div>
        </div>
      </li>
    </ul>
  </div>
</template>
