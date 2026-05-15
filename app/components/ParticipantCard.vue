<script setup lang="ts">
import type { Participant } from '~/types'

interface Props {
  participant: Participant
}

const props = defineProps<Props>()

defineEmits<{
  details: [participant: Participant]
}>()

const { stats } = useParticipantStats(() => props.participant.id)
const { formatShort } = useDateFormat()

const debtBadge = computed(() => {
  if (stats.value.entriesCount === 0) {
    return { label: 'Без записів', class: 'badge-info' }
  }
  return stats.value.unclosed > 0
    ? { label: 'Є борг', class: 'badge-warn' }
    : { label: 'Закрито', class: 'badge-ok' }
})
</script>

<template>
  <GlowCard
    interactive
    class="hover:border-cyan-300/30"
  >
    <div class="flex items-start justify-between gap-4 flex-wrap md:flex-nowrap">
      <div class="min-w-0 flex-1">
        <div class="flex items-center gap-2 flex-wrap">
          <h3 class="font-display text-lg md:text-xl font-bold text-cyan-100 truncate">
            {{ participant.nickname }}
          </h3>
          <span :class="debtBadge.class">{{ debtBadge.label }}</span>
        </div>
        <div
          v-if="participant.real_name"
          class="mt-0.5 text-sm text-slate-400 truncate"
        >
          {{ participant.real_name }}
        </div>

        <div class="mt-4 grid grid-cols-3 gap-3 max-w-md">
          <div>
            <div class="text-[10px] uppercase tracking-widest text-slate-500">
              Усього
            </div>
            <div class="font-display text-lg font-bold text-cyan-200">
              {{ stats.total }}
            </div>
          </div>
          <div>
            <div class="text-[10px] uppercase tracking-widest text-slate-500">
              Закрито
            </div>
            <div class="font-display text-lg font-bold text-emerald-200">
              {{ stats.closed }}
            </div>
          </div>
          <div>
            <div class="text-[10px] uppercase tracking-widest text-slate-500">
              Борг
            </div>
            <div
              class="font-display text-lg font-bold"
              :class="stats.unclosed > 0 ? 'text-amber-200' : 'text-slate-400'"
            >
              {{ stats.unclosed }}
            </div>
          </div>
        </div>
      </div>

      <div class="flex flex-col items-end gap-3 shrink-0">
        <div class="text-xs text-slate-500 text-right">
          <div class="uppercase tracking-widest text-[10px]">
            Останній запис
          </div>
          <div class="mt-0.5 text-slate-300">
            {{ formatShort(stats.lastEntryDate) }}
          </div>
        </div>
        <BaseButton
          variant="ghost"
          class="text-sm py-2 px-4"
          @click="$emit('details', participant)"
        >
          Детальніше
        </BaseButton>
      </div>
    </div>
  </GlowCard>
</template>
