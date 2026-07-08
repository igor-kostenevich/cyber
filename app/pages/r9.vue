<script setup lang="ts">
import type { Participant } from '~/types'

definePageMeta({
  middleware: 'approved',
})

useHead({ title: 'Збір на R9 · Cyberpunk' })

const participants = useParticipantsStore()
const entries = useEntriesStore()
const settings = useSettingsStore()

const joinModal = useModal()
const detailsModal = useModal<Participant>()

const approvedList = computed(() => participants.approved)
const isInitialLoading = computed(
  () => !participants.hasLoaded || !entries.hasLoaded || !settings.hasLoaded,
)
const errorMessage = computed(() => participants.error || entries.error)

const refresh = async (): Promise<void> => {
  await Promise.all([
    participants.fetchAll(),
    entries.fetchAll(),
    settings.fetch(),
  ])
}

if (import.meta.client) {
  void refresh()
}

const openDetails = (p: Participant): void => detailsModal.open(p)
</script>

<template>
  <div class="container-page pb-16">
    <AppHero />

    <div class="space-y-6">
      <ProgressCard />

      <div class="flex flex-wrap items-center justify-between gap-3">
        <h2 class="font-display text-xl md:text-2xl text-cyan-100">
          Учасники
          <span class="ml-2 text-slate-500 text-base font-normal">
            ({{ approvedList.length }})
          </span>
        </h2>
        <BaseButton @click="joinModal.open()">
          Хочу допомогти
        </BaseButton>
      </div>

      <EmptyState
        v-if="errorMessage"
        tone="error"
        title="Помилка завантаження"
        :description="errorMessage"
      >
        <template #actions>
          <BaseButton
            variant="ghost"
            @click="refresh"
          >
            Спробувати ще раз
          </BaseButton>
        </template>
      </EmptyState>

      <div
        v-else-if="isInitialLoading"
        class="space-y-3"
      >
        <div
          v-for="i in 3"
          :key="i"
          class="card-cyber p-5 space-y-3"
        >
          <SkeletonLine
            width="40%"
            height="1.25rem"
          />
          <SkeletonLine width="80%" />
          <SkeletonLine width="60%" />
        </div>
      </div>

      <EmptyState
        v-else-if="approvedList.length === 0"
        title="Учасників поки немає"
        description="Стань першим — подай заявку, і коли її підтвердять, ти зʼявишся тут."
      >
        <template #actions>
          <BaseButton @click="joinModal.open()">
            Подати заявку
          </BaseButton>
        </template>
      </EmptyState>

      <ul
        v-else
        class="space-y-3"
      >
        <li
          v-for="p in approvedList"
          :key="p.id"
        >
          <ParticipantCard
            :participant="p"
            @details="openDetails"
          />
        </li>
      </ul>
    </div>

    <JoinRequestModal
      :open="joinModal.isOpen.value"
      @update:open="(v) => (v ? joinModal.open() : joinModal.close())"
      @submitted="refresh"
    />

    <ParticipantDetailsModal
      :open="detailsModal.isOpen.value"
      :participant="detailsModal.payload.value"
      @update:open="(v) => (v ? null : detailsModal.close())"
    />
  </div>
</template>

<style scoped>
.container-page {
  width: 100%;
  max-width: 80rem;
  margin-left: auto;
  margin-right: auto;
  padding-left: 1rem;
  padding-right: 1rem;
}
@media (min-width: 768px) {
  .container-page {
    padding-left: 2rem;
    padding-right: 2rem;
  }
}
</style>
