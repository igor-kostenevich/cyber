<script setup lang="ts">
import type { Reward } from '~/types/activity'

interface Props {
  reward: Reward
  availableBalance: number
  pendingCount?: number
  queueTotal?: number
  submitting?: boolean
}

const props = withDefaults(defineProps<Props>(), {
  pendingCount: 0,
  queueTotal: 0,
  submitting: false,
})

const emit = defineEmits<{ request: [rewardId: string, qty: number] }>()

const qty = ref(1)

const inStock = computed(() => props.reward.is_available && props.reward.stock > 0)
const price = computed(() => props.reward.price_points)
const hasActiveRequest = computed(() => props.pendingCount > 0)

const maxQtyByBalance = computed(() => {
  if (price.value <= 0) return 0
  return Math.floor(props.availableBalance / price.value)
})

const maxQty = computed(() => {
  if (maxQtyByBalance.value <= 0) return 0
  if (inStock.value) return Math.min(maxQtyByBalance.value, props.reward.stock)
  return maxQtyByBalance.value
})

const canRequest = computed(() => maxQty.value > 0)

const isQueueRequest = computed(() => canRequest.value && !inStock.value)

const totalCost = computed(() => price.value * qty.value)

watch(
  () => [props.reward.id, maxQty.value] as const,
  () => {
    qty.value = maxQty.value > 0 ? 1 : 0
  },
)

watch(qty, (v) => {
  if (maxQty.value <= 0) {
    qty.value = 0
    return
  }
  if (!Number.isFinite(v) || v < 1) qty.value = 1
  else if (v > maxQty.value) qty.value = maxQty.value
})

const submit = () => {
  if (!canRequest.value || qty.value < 1) return
  emit('request', props.reward.id, qty.value)
}

const disabledReason = computed(() => {
  if (maxQtyByBalance.value <= 0) return 'Недостатньо CR'
  return 'Недоступно'
})
</script>

<template>
  <div
    class="card-cyber relative overflow-hidden flex flex-col transition-all duration-200"
    :class="[
      inStock ? '' : 'opacity-90',
      canRequest
        ? isQueueRequest
          ? 'shadow-glow-violet ring-1 ring-amber-400/30 hover:-translate-y-1'
          : 'shadow-glow-violet ring-1 ring-violet-400/35 hover:-translate-y-1 hover:shadow-[0_0_36px_rgba(167,139,250,0.45)]'
        : inStock ? 'hover:-translate-y-0.5' : '',
    ]"
  >
    <div
      class="pointer-events-none absolute inset-x-0 top-0 h-px bg-gradient-to-r from-transparent via-cyan-400/50 to-transparent"
      :class="canRequest ? (isQueueRequest ? 'via-amber-400/50' : 'via-violet-400/60') : ''"
    />

    <div class="relative aspect-video w-full overflow-hidden bg-ink-800/60 grid place-items-center">
      <img
        v-if="reward.image_url"
        :src="reward.image_url"
        :alt="reward.name"
        class="max-h-[9rem] max-w-[85%] w-auto object-contain"
        loading="lazy"
        decoding="async"
      >
      <span
        v-else
        class="text-4xl opacity-60 select-none"
      >🎁</span>

      <span
        v-if="!inStock"
        class="absolute top-2 right-2 badge-warn text-[10px]"
      >
        Немає на складі
      </span>
      <span
        v-else
        class="absolute top-2 right-2 badge-ok text-[10px]"
      >
        На складі: {{ reward.stock }}
      </span>

      <span
        v-if="hasActiveRequest"
        class="absolute top-2 left-2 badge-info text-[10px]"
      >
        {{ pendingCount === 1 ? 'У заявці' : `У заявках: ${pendingCount}` }}
      </span>
      <span
        v-else-if="!inStock && queueTotal > 0"
        class="absolute top-2 left-2 badge-warn text-[10px]"
      >
        Черга: {{ queueTotal }}
      </span>
    </div>

    <div class="p-4 flex flex-col gap-3 flex-1">
      <div class="flex-1">
        <h3 class="font-display text-base text-slate-100 leading-tight">
          {{ reward.name }}
        </h3>
        <div class="mt-1.5">
          <span class="badge-info text-xs inline-flex items-center gap-1">
            <CyberPoints
              :value="price"
              show-word
              icon-size="xs"
            />
          </span>
        </div>
        <p
          v-if="isQueueRequest"
          class="mt-2 text-[11px] text-amber-200/80 leading-snug"
        >
          Можна встати в чергу — Cyber-кредити спишуться після видачі, коли зʼявиться на складі.
        </p>
      </div>

      <div
        v-if="canRequest"
        class="space-y-2"
      >
        <div class="flex items-end gap-2">
          <div class="w-[4.5rem] shrink-0">
            <label
              class="label text-[10px] mb-1"
              :for="`reward-qty-${reward.id}`"
            >К-сть</label>
            <input
              :id="`reward-qty-${reward.id}`"
              v-model.number="qty"
              type="number"
              min="1"
              :max="maxQty"
              class="input py-2 px-2 text-center tabular-nums"
            >
          </div>
          <BaseButton
            class="flex-1"
            :variant="isQueueRequest ? 'warn' : 'primary'"
            :loading="submitting"
            @click="submit"
          >
            {{ isQueueRequest ? 'В чергу' : 'Запросити' }}
          </BaseButton>
        </div>
        <p class="text-[11px] text-slate-500 text-center flex items-center justify-center gap-1 flex-wrap">
          <span>=</span>
          <CyberPoints
            :value="totalCost"
            icon-size="xs"
            muted
          />
          <span>· макс. {{ maxQty }}</span>
          <template v-if="isQueueRequest && queueTotal > 0">
            · зараз у черзі: {{ queueTotal }}
          </template>
        </p>
      </div>

      <div
        v-else
        class="text-center"
      >
        <BaseButton
          variant="ghost"
          disabled
          full-width
        >
          {{ disabledReason }}
        </BaseButton>
      </div>
    </div>
  </div>
</template>
