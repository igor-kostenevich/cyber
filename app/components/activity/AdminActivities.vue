<script setup lang="ts">
import type { ActivityType } from '~/types/activity'

const players = usePlayersStore()
const activities = useActivitiesStore()
const settings = useActivitySettingsStore()
const { get } = useActivityTypes()
const { format } = useDateFormat()

const modalOpen = ref(false)
const selectedType = ref<ActivityType | null>(null)

const refresh = async () => {
  await Promise.all([players.fetchAll(), activities.fetchRecent(), settings.fetch()])
}

onMounted(() => {
  void refresh()
})

const openModal = (type: ActivityType) => {
  selectedType.value = type
  modalOpen.value = true
}

const onCreated = async () => {
  await refresh()
}
</script>

<template>
  <div class="space-y-6">
    <section class="space-y-3">
      <h3 class="font-display text-lg text-cyan-100">
        Швидке створення івенту
      </h3>
      <QuickActivityButtons
        editable
        @select="openModal"
      />
    </section>

    <section class="space-y-3">
      <h3 class="font-display text-lg text-cyan-100">
        Останні нарахування
      </h3>

      <div
        v-if="activities.isLoading && !activities.hasLoaded"
        class="space-y-2"
      >
        <SkeletonLine
          v-for="i in 3"
          :key="i"
          height="3rem"
          rounded="rounded-xl"
        />
      </div>

      <EmptyState
        v-else-if="activities.items.length === 0"
        title="Активностей поки немає"
        description="Створіть перший івент кнопками вище."
      />

      <ul
        v-else
        class="space-y-2"
      >
        <li
          v-for="a in activities.items"
          :key="a.id"
          class="glass rounded-xl px-4 py-3 flex items-center gap-3"
        >
          <span class="text-lg">{{ get(a.type).emoji }}</span>
          <div class="flex-1 min-w-0">
            <div class="text-sm text-slate-100">
              {{ get(a.type).label }}
              <span
                v-if="a.description"
                class="text-slate-400"
              >· {{ a.description }}</span>
            </div>
            <div class="text-xs text-slate-500">
              {{ format(a.activity_date) }}
            </div>
          </div>
          <span class="badge-info text-xs">
            <CyberPoints
              :value="a.points"
              sign="+"
              icon-size="xs"
            />
          </span>
        </li>
      </ul>
    </section>

    <ActivityCreateModal
      v-model:open="modalOpen"
      :type="selectedType"
      :players="players.approved"
      @created="onCreated"
    />
  </div>
</template>
