<script setup lang="ts">
import type { Participant } from '~/types'

interface Props {
  open: boolean
  participant: Participant | null
}

const props = defineProps<Props>()

defineEmits<{
  'update:open': [value: boolean]
  close: []
}>()

const entries = useEntriesStore()
const { format } = useDateFormat()
const { stats } = useParticipantStats(() => props.participant?.id ?? '')

const list = computed(() =>
  props.participant ? entries.forParticipant(props.participant.id) : [],
)
</script>

<template>
  <BaseModal
    :open="open"
    size="lg"
    :title="participant?.nickname || 'Учасник'"
    :description="participant?.real_name || undefined"
    @update:open="(v) => $emit('update:open', v)"
    @close="$emit('close')"
  >
    <div
      v-if="participant"
      class="space-y-5"
    >
      <div class="grid grid-cols-3 gap-3">
        <div class="p-3 rounded-xl bg-white/[0.04] border border-white/10 text-center">
          <div class="text-[10px] uppercase tracking-widest text-slate-400">
            Усього
          </div>
          <div class="font-display text-xl font-bold text-cyan-200">
            {{ stats.total }}
          </div>
        </div>
        <div class="p-3 rounded-xl bg-white/[0.04] border border-white/10 text-center">
          <div class="text-[10px] uppercase tracking-widest text-slate-400">
            Закрито
          </div>
          <div class="font-display text-xl font-bold text-emerald-200">
            {{ stats.closed }}
          </div>
        </div>
        <div class="p-3 rounded-xl bg-white/[0.04] border border-white/10 text-center">
          <div class="text-[10px] uppercase tracking-widest text-slate-400">
            Борг
          </div>
          <div
            class="font-display text-xl font-bold"
            :class="stats.unclosed > 0 ? 'text-amber-200' : 'text-slate-300'"
          >
            {{ stats.unclosed }}
          </div>
        </div>
      </div>

      <div
        v-if="participant.comment"
        class="rounded-xl bg-white/[0.03] border border-white/10 p-4 text-sm text-slate-300"
      >
        <div class="text-[10px] uppercase tracking-widest text-slate-500 mb-1">
          Коментар
        </div>
        {{ participant.comment }}
      </div>

      <div>
        <div class="flex items-center justify-between mb-2">
          <h4 class="font-display text-sm uppercase tracking-widest text-cyan-300/80">
            Записи ({{ list.length }})
          </h4>
        </div>

        <div
          v-if="list.length === 0"
          class="rounded-xl bg-white/[0.03] border border-white/10 p-6 text-center text-sm text-slate-400"
        >
          Поки немає жодного запису
        </div>

        <ul
          v-else
          class="space-y-2 max-h-80 overflow-y-auto pr-1"
        >
          <li
            v-for="entry in list"
            :key="entry.id"
            class="rounded-xl bg-white/[0.03] border border-white/10 p-3 flex items-start gap-3"
          >
            <div class="shrink-0 w-20 text-xs text-slate-400">
              {{ format(entry.entry_date) }}
            </div>
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2 text-sm">
                <span class="text-cyan-200 font-semibold">{{ entry.seals_count }}</span>
                <span class="text-slate-500">/</span>
                <span class="text-emerald-200">{{ entry.closed_count }}</span>
                <span class="text-slate-500 text-xs ml-1">закрито</span>
                <span
                  v-if="entry.seals_count - entry.closed_count > 0"
                  class="badge-warn ml-1"
                >
                  борг: {{ entry.seals_count - entry.closed_count }}
                </span>
                <span
                  v-else
                  class="badge-ok ml-1"
                >
                  ОК
                </span>
              </div>
              <div
                v-if="entry.comment"
                class="mt-1 text-xs text-slate-400"
              >
                {{ entry.comment }}
              </div>
            </div>
          </li>
        </ul>
      </div>
    </div>
  </BaseModal>
</template>
