<script setup lang="ts">
import type { RewardRequestStatus, RewardRequestView } from '~/types/activity'
import {
  isActiveRewardRequest,
  rewardRequestStatusMeta,
} from '~/composables/useRewardRequestQueue'

const requests = useRewardRequestsStore()
const { getMessage } = useSupabaseErrorMessage()
const { format } = useDateFormat()

type Filter = RewardRequestStatus | 'all' | 'active'
const filter = ref<string>('active')

const busyId = ref<string | null>(null)
const actionError = ref<string | null>(null)

onMounted(() => {
  if (!requests.hasLoaded) void requests.fetchAll()
})

const filters: Array<{ id: Filter, label: string }> = [
  { id: 'active', label: 'Очікують' },
  { id: 'completed', label: 'Видані' },
  { id: 'rejected', label: 'Відхилені' },
  { id: 'all', label: 'Усі' },
]

const visible = computed(() => {
  let rows = requests.items
  if (filter.value === 'active') {
    rows = rows.filter((r) => isActiveRewardRequest(r.status))
  }
  else if (filter.value !== 'all') {
    rows = rows.filter((r) => r.status === filter.value)
  }

  return [...rows].sort((a, b) => {
    if (isActiveRewardRequest(a.status) && isActiveRewardRequest(b.status)) {
      if (a.reward_id !== b.reward_id) {
        return (a.reward?.name ?? '').localeCompare(b.reward?.name ?? '')
      }
      return a.created_at.localeCompare(b.created_at)
    }
    return b.created_at.localeCompare(a.created_at)
  })
})

const activeCount = computed(() => requests.active.length)

function statusFor(req: RewardRequestView) {
  const inStock = (req.reward?.stock ?? 0) >= req.quantity
  return rewardRequestStatusMeta(req.status, {
    queuePosition: requests.getQueuePosition(req.id),
    inStock,
  })
}

const run = async (id: string, fn: () => Promise<void>) => {
  busyId.value = id
  actionError.value = null
  try {
    await fn()
    await requests.fetchAll()
  }
  catch (e) {
    actionError.value = getMessage(e, 'Дію не виконано')
  }
  finally {
    busyId.value = null
  }
}

const grant = (id: string) => run(id, () => requests.grant(id))
const reject = (id: string) => run(id, () => requests.reject(id))
</script>

<template>
  <div class="space-y-4">
    <AdminTabs
      v-model="filter"
      :tabs="filters.map((f) => ({ id: f.id, label: f.label, badge: f.id === 'active' ? activeCount : undefined }))"
    />

    <div
      v-if="actionError"
      class="text-sm text-rose-300 bg-rose-500/10 border border-rose-400/30 rounded-lg px-3 py-2"
    >
      {{ actionError }}
    </div>

    <EmptyState
      v-if="requests.error"
      tone="error"
      title="Помилка завантаження"
      :description="requests.error"
    />

    <div
      v-else-if="requests.isLoading && !requests.hasLoaded"
      class="space-y-2"
    >
      <SkeletonLine
        v-for="i in 3"
        :key="i"
        height="4rem"
        rounded="rounded-xl"
      />
    </div>

    <EmptyState
      v-else-if="visible.length === 0"
      title="Заявок немає"
      description="У цьому розділі поки порожньо."
    />

    <ul
      v-else
      class="space-y-2"
    >
      <li
        v-for="req in visible"
        :key="req.id"
        class="glass rounded-xl p-4 flex flex-col lg:flex-row lg:items-center gap-4"
        :class="isActiveRewardRequest(req.status) ? 'ring-1 ring-white/5' : 'opacity-70'"
      >
        <div class="flex-1 min-w-0 space-y-2">
          <div class="flex items-start gap-2 flex-wrap">
            <span
              v-if="isActiveRewardRequest(req.status) && requests.getQueuePosition(req.id)"
              class="badge-warn text-[10px] shrink-0 mt-0.5"
            >
              #{{ requests.getQueuePosition(req.id) }} у черзі
            </span>
            <div class="min-w-0">
              <span class="text-sm font-medium text-slate-100">
                {{ req.profile?.nickname ?? '—' }}
              </span>
              <span class="text-slate-400 text-sm"> → </span>
              <span class="text-sm text-slate-100">{{ req.reward?.name ?? '—' }}</span>
            </div>
          </div>

          <div class="flex flex-wrap gap-3 text-xs">
            <span class="text-slate-500">{{ format(req.created_at) }}</span>

            <span class="inline-flex items-center gap-1 text-slate-400">
              <template v-if="req.quantity > 1">
                {{ req.quantity }} ×
                <CyberPoints
                  :value="req.price_points"
                  icon-size="xs"
                  muted
                  class="inline-flex"
                />
                <span class="text-slate-600">=</span>
                <CyberPoints
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
            </span>

            <span class="inline-flex items-center gap-1 text-slate-400">
              Баланс:
              <CyberPoints
                :value="req.profile?.points_balance ?? 0"
                icon-size="xs"
                muted
                class="inline-flex"
              />
            </span>

            <span
              class="text-slate-400"
              :class="(req.reward?.stock ?? 0) === 0 ? 'text-rose-400/80' : ''"
            >
              На складі: {{ req.reward?.stock ?? 0 }}
            </span>
          </div>
        </div>

        <div class="flex items-center gap-2 shrink-0">
          <template v-if="isActiveRewardRequest(req.status)">
            <BaseButton
              size="sm"
              :loading="busyId === req.id"
              :disabled="(req.reward?.stock ?? 0) < req.quantity"
              @click="grant(req.id)"
            >
              Видати{{ req.quantity > 1 ? ` ×${req.quantity}` : '' }}
            </BaseButton>
            <BaseButton
              variant="danger"
              :disabled="busyId === req.id"
              @click="reject(req.id)"
            >
              Відхилити
            </BaseButton>
          </template>
          <span
            v-else
            :class="statusFor(req).cls"
          >
            {{ statusFor(req).label }}
          </span>
        </div>
      </li>
    </ul>
  </div>
</template>
