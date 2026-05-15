<script setup lang="ts">
import type { Participant } from '~/types'

const participants = useParticipantsStore()
const { format } = useDateFormat()

const pendingList = computed(() => participants.pending)
const processing = ref<Set<string>>(new Set())
const errorMap = ref<Map<string, string>>(new Map())

const setProcessing = (id: string, value: boolean) => {
  const next = new Set(processing.value)
  if (value) next.add(id)
  else next.delete(id)
  processing.value = next
}

const handle = async (p: Participant, action: 'approved' | 'rejected') => {
  setProcessing(p.id, true)
  errorMap.value.delete(p.id)
  try {
    await participants.updateStatus(p.id, action)
  }
  catch (e) {
    const message = e instanceof Error ? e.message : 'Помилка операції'
    errorMap.value.set(p.id, message)
  }
  finally {
    setProcessing(p.id, false)
  }
}
</script>

<template>
  <section class="space-y-4">
    <header class="flex items-center justify-between">
      <h2 class="font-display text-xl text-cyan-100">
        Заявки на участь
        <span class="ml-2 text-slate-500 text-base">({{ pendingList.length }})</span>
      </h2>
    </header>

    <div
      v-if="participants.isLoading && pendingList.length === 0"
      class="space-y-3"
    >
      <div
        v-for="i in 2"
        :key="i"
        class="card-cyber p-5 space-y-3"
      >
        <SkeletonLine
          width="40%"
          height="1rem"
        />
        <SkeletonLine width="60%" />
        <SkeletonLine width="30%" />
      </div>
    </div>

    <EmptyState
      v-else-if="pendingList.length === 0"
      title="Нових заявок немає"
      description="Щойно хтось подасть запит — він зʼявиться тут."
    />

    <ul
      v-else
      class="space-y-3"
    >
      <li
        v-for="p in pendingList"
        :key="p.id"
        class="card-cyber p-5"
      >
        <div class="flex flex-wrap items-start justify-between gap-4">
          <div class="min-w-0 flex-1">
            <div class="flex items-center gap-2 flex-wrap">
              <h3 class="font-display text-lg text-cyan-100">
                {{ p.nickname }}
              </h3>
              <span class="badge-warn">pending</span>
            </div>
            <div
              v-if="p.real_name"
              class="text-sm text-slate-400 mt-0.5"
            >
              {{ p.real_name }}
            </div>
            <div
              v-if="p.comment"
              class="mt-2 text-sm text-slate-300/90 rounded-lg bg-white/[0.03] border border-white/10 px-3 py-2"
            >
              {{ p.comment }}
            </div>
            <div class="mt-2 text-xs text-slate-500">
              Подано: {{ format(p.created_at) }}
            </div>
          </div>

          <div class="flex items-center gap-2 shrink-0">
            <BaseButton
              variant="ghost"
              :loading="processing.has(p.id)"
              @click="handle(p, 'rejected')"
            >
              Відхилити
            </BaseButton>
            <BaseButton
              :loading="processing.has(p.id)"
              @click="handle(p, 'approved')"
            >
              Підтвердити
            </BaseButton>
          </div>
        </div>

        <div
          v-if="errorMap.get(p.id)"
          class="mt-3 text-sm text-rose-300 bg-rose-500/10 border border-rose-400/30 rounded-lg px-3 py-2"
        >
          {{ errorMap.get(p.id) }}
        </div>
      </li>
    </ul>
  </section>
</template>
