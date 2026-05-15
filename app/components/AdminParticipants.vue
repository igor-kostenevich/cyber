<script setup lang="ts">
import type { Participant, SealEntry } from '~/types'

const participants = useParticipantsStore()
const entries = useEntriesStore()
const { format, formatShort } = useDateFormat()

const approvedList = computed<Participant[]>(() => participants.approved)
const expanded = ref<Set<string>>(new Set())

const toggleExpanded = (id: string) => {
  const next = new Set(expanded.value)
  if (next.has(id)) next.delete(id)
  else next.add(id)
  expanded.value = next
}

const entryModal = reactive({
  open: false,
  entry: null as SealEntry | null,
  preselectedParticipantId: null as string | null,
})

const editModal = reactive({
  open: false,
  participant: null as Participant | null,
})

const openCreateEntry = (p: Participant) => {
  entryModal.entry = null
  entryModal.preselectedParticipantId = p.id
  entryModal.open = true
}

const openEditEntry = (entry: SealEntry) => {
  entryModal.entry = entry
  entryModal.preselectedParticipantId = entry.participant_id
  entryModal.open = true
}

const openEditParticipant = (p: Participant) => {
  editModal.participant = p
  editModal.open = true
}

const removingParticipant = ref<string | null>(null)
const removingEntry = ref<string | null>(null)

const onRemoveParticipant = async (p: Participant) => {
  const ok = confirm(
    `Видалити учасника "${p.nickname}" разом із усіма його записами?`,
  )
  if (!ok) return
  removingParticipant.value = p.id
  try {
    await participants.remove(p.id)
  }
  catch (e) {
    alert(e instanceof Error ? e.message : 'Не вдалося видалити')
  }
  finally {
    removingParticipant.value = null
  }
}

const onRemoveEntry = async (entry: SealEntry) => {
  const ok = confirm('Видалити цей запис?')
  if (!ok) return
  removingEntry.value = entry.id
  try {
    await entries.remove(entry.id)
  }
  catch (e) {
    alert(e instanceof Error ? e.message : 'Не вдалося видалити')
  }
  finally {
    removingEntry.value = null
  }
}

const quickClose = async (entry: SealEntry) => {
  if (entry.seals_count - entry.closed_count <= 0) return
  try {
    await entries.update(entry.id, { closed_count: entry.seals_count })
  }
  catch (e) {
    alert(e instanceof Error ? e.message : 'Не вдалося оновити')
  }
}

const totalsByParticipant = (id: string) => {
  const list = entries.forParticipant(id)
  const total = list.reduce((s, e) => s + e.seals_count, 0)
  const closed = list.reduce((s, e) => s + e.closed_count, 0)
  return { total, closed, unclosed: total - closed, count: list.length }
}
</script>

<template>
  <section class="space-y-4">
    <header class="flex items-center justify-between flex-wrap gap-3">
      <h2 class="font-display text-xl text-cyan-100">
        Учасники
        <span class="ml-2 text-slate-500 text-base">({{ approvedList.length }})</span>
      </h2>
      <BaseButton
        :disabled="approvedList.length === 0"
        @click="openCreateEntry(approvedList[0])"
      >
        Новий запис
      </BaseButton>
    </header>

    <div
      v-if="participants.isLoading && approvedList.length === 0"
      class="space-y-3"
    >
      <div
        v-for="i in 3"
        :key="i"
        class="card-cyber p-5 space-y-3"
      >
        <SkeletonLine width="40%" />
        <SkeletonLine width="80%" />
      </div>
    </div>

    <EmptyState
      v-else-if="approvedList.length === 0"
      title="Немає підтверджених учасників"
      description="Підтверди заявку у вкладці «Заявки», щоб учасник зʼявився тут."
    />

    <ul
      v-else
      class="space-y-3"
    >
      <li
        v-for="p in approvedList"
        :key="p.id"
        class="card-cyber p-5"
      >
        <div class="flex flex-wrap items-start justify-between gap-4">
          <div class="min-w-0 flex-1">
            <div class="flex items-center gap-2 flex-wrap">
              <h3 class="font-display text-lg text-cyan-100">
                {{ p.nickname }}
              </h3>
              <span
                v-if="totalsByParticipant(p.id).unclosed > 0"
                class="badge-warn"
              >
                Борг: {{ totalsByParticipant(p.id).unclosed }}
              </span>
              <span
                v-else-if="totalsByParticipant(p.id).count > 0"
                class="badge-ok"
              >
                Закрито
              </span>
            </div>
            <div
              v-if="p.real_name"
              class="text-sm text-slate-400 mt-0.5"
            >
              {{ p.real_name }}
            </div>

            <div class="mt-3 grid grid-cols-3 gap-3 max-w-md">
              <div>
                <div class="text-[10px] uppercase tracking-widest text-slate-500">
                  Усього
                </div>
                <div class="font-display text-lg font-bold text-cyan-200">
                  {{ totalsByParticipant(p.id).total }}
                </div>
              </div>
              <div>
                <div class="text-[10px] uppercase tracking-widest text-slate-500">
                  Закрито
                </div>
                <div class="font-display text-lg font-bold text-emerald-200">
                  {{ totalsByParticipant(p.id).closed }}
                </div>
              </div>
              <div>
                <div class="text-[10px] uppercase tracking-widest text-slate-500">
                  Записів
                </div>
                <div class="font-display text-lg font-bold text-slate-200">
                  {{ totalsByParticipant(p.id).count }}
                </div>
              </div>
            </div>
          </div>

          <div class="flex flex-wrap items-center gap-2 shrink-0">
            <BaseButton
              variant="ghost"
              class="text-sm py-2 px-3"
              @click="toggleExpanded(p.id)"
            >
              {{ expanded.has(p.id) ? 'Згорнути' : `Записи (${totalsByParticipant(p.id).count})` }}
            </BaseButton>
            <BaseButton
              class="text-sm py-2 px-3"
              @click="openCreateEntry(p)"
            >
              + Запис
            </BaseButton>
            <BaseButton
              variant="ghost"
              class="text-sm py-2 px-3"
              @click="openEditParticipant(p)"
            >
              Редагувати
            </BaseButton>
            <BaseButton
              variant="danger"
              class="text-sm py-2 px-3"
              :loading="removingParticipant === p.id"
              @click="onRemoveParticipant(p)"
            >
              Видалити
            </BaseButton>
          </div>
        </div>

        <div
          v-if="expanded.has(p.id)"
          class="mt-4 border-t border-white/5 pt-4"
        >
          <ul
            v-if="entries.forParticipant(p.id).length"
            class="space-y-2"
          >
            <li
              v-for="entry in entries.forParticipant(p.id)"
              :key="entry.id"
              class="rounded-xl bg-white/[0.03] border border-white/10 p-3 flex flex-wrap items-start justify-between gap-3"
            >
              <div class="min-w-0">
                <div class="flex items-center gap-2 flex-wrap text-sm">
                  <span class="text-xs text-slate-400 w-20">
                    {{ format(entry.entry_date) }}
                  </span>
                  <span class="text-cyan-200 font-semibold">{{ entry.seals_count }}</span>
                  <span class="text-slate-500">/</span>
                  <span class="text-emerald-200">{{ entry.closed_count }}</span>
                  <span
                    v-if="entry.seals_count - entry.closed_count > 0"
                    class="badge-warn"
                  >
                    борг: {{ entry.seals_count - entry.closed_count }}
                  </span>
                  <span
                    v-else
                    class="badge-ok"
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
              <div class="flex items-center gap-2">
                <BaseButton
                  v-if="entry.seals_count - entry.closed_count > 0"
                  variant="ghost"
                  class="text-xs py-1.5 px-3"
                  @click="quickClose(entry)"
                >
                  Закрити все
                </BaseButton>
                <BaseButton
                  variant="ghost"
                  class="text-xs py-1.5 px-3"
                  @click="openEditEntry(entry)"
                >
                  Редагувати
                </BaseButton>
                <BaseButton
                  variant="danger"
                  class="text-xs py-1.5 px-3"
                  :loading="removingEntry === entry.id"
                  @click="onRemoveEntry(entry)"
                >
                  Видалити
                </BaseButton>
              </div>
            </li>
          </ul>
          <div
            v-else
            class="text-sm text-slate-400 italic px-1"
          >
            Поки немає записів. Додай перший — кнопкою «+ Запис».
          </div>
          <div
            v-if="entries.forParticipant(p.id).length"
            class="mt-2 text-[10px] text-slate-500"
          >
            Останній запис: {{ formatShort(entries.forParticipant(p.id)[0]?.entry_date) }}
          </div>
        </div>
      </li>
    </ul>

    <AdminEntryForm
      :open="entryModal.open"
      :entry="entryModal.entry"
      :preselected-participant-id="entryModal.preselectedParticipantId"
      @update:open="(v) => (entryModal.open = v)"
    />

    <AdminParticipantEditModal
      :open="editModal.open"
      :participant="editModal.participant"
      @update:open="(v) => (editModal.open = v)"
    />
  </section>
</template>
