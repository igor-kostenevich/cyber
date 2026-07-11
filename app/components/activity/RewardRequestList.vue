<script setup lang="ts">
import type { RewardRequestView } from '~/types/activity'
import { isActiveRewardRequest, rewardRequestStatusMeta } from '~/composables/useRewardRequestQueue'

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

const requestsStore = useRewardRequestsStore()
const { getMessage } = useSupabaseErrorMessage()
const { format } = useDateFormat()

const cancellingId = ref<string | null>(null)
const cancelError = ref<string | null>(null)

async function cancelRequest(id: string) {
  cancellingId.value = id
  cancelError.value = null
  try {
    await requestsStore.cancel(id)
    await requestsStore.fetchAll()
  }
  catch (e) {
    cancelError.value = getMessage(e, 'Не вдалося скасувати заявку')
  }
  finally {
    cancellingId.value = null
  }
}

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

    <div
      v-else
      class="space-y-3"
    >
      <div
        v-if="cancelError"
        class="text-sm text-rose-300 bg-rose-500/10 border border-rose-400/30 rounded-lg px-3 py-2"
      >
        {{ cancelError }}
      </div>

      <ul class="space-y-2">
        <li
          v-for="req in requests"
          :key="req.id"
          class="glass rounded-xl px-4 py-3 flex items-center justify-between gap-3"
          :class="isActiveRewardRequest(req.status) ? 'ring-1 ring-white/5' : 'opacity-75'"
        >
          <div class="min-w-0 flex-1">
            <div class="flex items-center gap-2 flex-wrap">
              <span class="text-sm font-medium text-slate-100 truncate">
                {{ req.reward?.name ?? 'Нагорода' }}
              </span>
              <span
                v-if="queuePositions.get(req.id)"
                class="badge-warn text-[10px] shrink-0"
              >
                #{{ queuePositions.get(req.id) }} у черзі
              </span>
            </div>
            <div class="mt-1 flex items-center gap-2 flex-wrap text-xs text-slate-500">
              <span>{{ format(req.created_at) }}</span>
              <span class="text-slate-600">·</span>
              <span class="inline-flex items-center gap-1">
                <template v-if="req.quantity > 1">
                  {{ req.quantity }} ×
                  <CyberPoints
                    :value="req.price_points"
                    icon-size="xs"
                    muted
                    class="inline-flex"
                  />
                  <span>=</span>
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
            </div>
          </div>

          <div class="flex items-center gap-2 shrink-0">
            <span :class="statusFor(req).cls">
              {{ statusFor(req).label }}
            </span>
            <button
              v-if="isActiveRewardRequest(req.status)"
              class="text-xs text-slate-500 hover:text-rose-400 transition-colors px-1.5 py-0.5 rounded hover:bg-rose-500/10"
              :disabled="cancellingId === req.id"
              :title="'Скасувати заявку'"
              @click="cancelRequest(req.id)"
            >
              <span v-if="cancellingId === req.id" class="inline-block h-3 w-3 rounded-full border border-current border-t-transparent animate-spin" />
              <span v-else>✕</span>
            </button>
          </div>
        </li>
      </ul>
    </div>
  </div>
</template>
