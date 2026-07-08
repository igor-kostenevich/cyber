<script setup lang="ts">
import type { RewardRequestView } from '~/types/activity'
import { rewardRequestStatusMeta } from '~/composables/useRewardRequestQueue'

interface Props {
  requests: RewardRequestView[]
  loading?: boolean
  error?: string | null
  queuePositions?: Map<string, number>
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  error: null,
  queuePositions: () => new Map(),
})

const { format } = useDateFormat()

function statusFor(req: RewardRequestView) {
  const inStock = (req.reward?.stock ?? 0) >= req.quantity
  return rewardRequestStatusMeta(req.status, {
    queuePosition: props.queuePositions.get(req.id) ?? null,
    inStock,
  })
}
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
      v-else-if="requests.length === 0"
      title="Заявок поки немає"
      description="Тут зʼявляться ваші заявки на нагороди."
    />

    <ul
      v-else
      class="space-y-2"
    >
      <li
        v-for="req in requests"
        :key="req.id"
        class="glass rounded-xl px-4 py-3 flex items-center justify-between gap-3"
      >
        <div class="min-w-0">
          <div class="text-sm text-slate-100 truncate">
            {{ req.reward?.name ?? 'Нагорода' }}
          </div>
          <div class="text-xs text-slate-500">
            {{ format(req.created_at) }}
            ·
            <template v-if="req.quantity > 1">
              {{ req.quantity }} × <CyberPoints
                :value="req.price_points"
                icon-size="xs"
                muted
                class="inline-flex"
              /> = <CyberPoints
                :value="rewardRequestTotalPoints(req)"
                icon-size="xs"
                muted
                class="inline-flex"
              />
            </template>
            <template v-else>
              <CyberPoints
                :value="req.price_points"
                icon-size="xs"
                muted
                class="inline-flex"
              />
            </template>
            <template v-if="queuePositions.get(req.id)">
              · {{ queuePositions.get(req.id) }}‑й у черзі
            </template>
          </div>
        </div>
        <span :class="statusFor(req).cls">
          {{ statusFor(req).label }}
        </span>
      </li>
    </ul>
  </div>
</template>
