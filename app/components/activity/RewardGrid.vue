<script setup lang="ts">
import type { Reward } from '~/types/activity'

interface Props {
  rewards: Reward[]
  availableBalance: number
  pendingCounts?: Record<string, number>
  queueTotals?: Record<string, number>
  loading?: boolean
  error?: string | null
  submittingId?: string | null
}

const props = withDefaults(defineProps<Props>(), {
  pendingCounts: () => ({}),
  queueTotals: () => ({}),
  loading: false,
  error: null,
  submittingId: null,
})

const emit = defineEmits<{ request: [rewardId: string, qty: number] }>()
</script>

<template>
  <div>
    <EmptyState
      v-if="error"
      tone="error"
      title="Помилка завантаження"
      :description="error"
    />

    <div
      v-else-if="loading"
      class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3"
    >
      <div
        v-for="i in 6"
        :key="i"
        class="card-cyber p-4 space-y-3"
      >
        <SkeletonLine
          height="8rem"
          rounded="rounded-xl"
        />
        <SkeletonLine width="70%" />
        <SkeletonLine width="40%" />
      </div>
    </div>

    <EmptyState
      v-else-if="rewards.length === 0"
      title="Нагород поки немає"
      description="Склад порожній. Зверніться до адміністрації клану."
    />

    <div
      v-else
      class="grid gap-4 sm:grid-cols-2 lg:grid-cols-3"
    >
      <RewardCard
        v-for="reward in rewards"
        :key="reward.id"
        :reward="reward"
        :available-balance="availableBalance"
        :pending-count="pendingCounts[reward.id] ?? 0"
        :queue-total="queueTotals[reward.id] ?? 0"
        :submitting="submittingId === reward.id"
        @request="(id, qty) => emit('request', id, qty)"
      />
    </div>
  </div>
</template>
