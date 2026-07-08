<script setup lang="ts">
import type { HistoryEntryView, HistoryType } from '~/types/activity'
import { HISTORY_ADMIN_ACTION_TYPES } from '~/composables/useHistoryFilters'

interface Props {
  entries: HistoryEntryView[]
  loading?: boolean
  error?: string | null
  /** Показувати ім'я гравця (для загальної історії в адмінці). */
  showSubject?: boolean
}

withDefaults(defineProps<Props>(), {
  loading: false,
  error: null,
  showSubject: false,
})

const { format } = useDateFormat()
const { label: activityLabel } = useActivityTypes()
const { parsePointsAwardDescription } = useActivityAward()

const meta: Record<HistoryType, { emoji: string, label: string }> = {
  points_award: { emoji: '➕', label: 'Нараховано CR' },
  points_spend: { emoji: '➖', label: 'Списано CR' },
  reward_grant: { emoji: '🎁', label: 'Видано нагороду' },
  reward_request: { emoji: '📨', label: 'Заявка на нагороду' },
  stock_add: { emoji: '📦', label: 'Поповнення складу' },
  user_register: { emoji: '🆕', label: 'Реєстрація гравця' },
  user_approve: { emoji: '✅', label: 'Підтвердження гравця' },
  user_status: { emoji: '🔄', label: 'Зміна статусу' },
  role_change: { emoji: '⭐', label: 'Зміна ролі' },
  reward_update: { emoji: '✏️', label: 'Оновлення нагороди' },
}

const REWARD_HISTORY_TYPES: HistoryType[] = [
  'reward_grant',
  'reward_request',
  'points_spend',
]

const isPositive = (t: HistoryType) => t === 'points_award'
const isNegative = (t: HistoryType) => t === 'points_spend'

function isRewardEntry(type: HistoryType): boolean {
  return REWARD_HISTORY_TYPES.includes(type)
}

function showActor(entry: HistoryEntryView): boolean {
  if (!entry.actor?.nickname) return false
  return HISTORY_ADMIN_ACTION_TYPES.includes(entry.type)
}

function actorPrefix(type: HistoryType): string {
  if (type === 'reward_grant' || type === 'user_approve') return 'Адмін'
  return 'Виконав'
}

function entryEmoji(entry: HistoryEntryView): string {
  return meta[entry.type]?.emoji ?? '•'
}

function activityTypeLabel(entry: HistoryEntryView): string | null {
  if (entry.type !== 'points_award' || !entry.description) return null
  const parsed = parsePointsAwardDescription(entry.description)
  if (!parsed.activityType) return null
  return activityLabel(parsed.activityType as Parameters<typeof activityLabel>[0])
}

function pointsAwardDetails(entry: HistoryEntryView) {
  if (entry.type !== 'points_award' || !entry.description) {
    return { includeMain: false, twinNames: [] as string[] }
  }
  const parsed = parsePointsAwardDescription(entry.description)
  return { includeMain: parsed.includeMain, twinNames: parsed.twinNames }
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
        v-for="i in 5"
        :key="i"
        height="3rem"
        rounded="rounded-xl"
      />
    </div>

    <EmptyState
      v-else-if="entries.length === 0"
      title="Нічого не знайдено"
      description="Спробуйте інший фільтр або період."
    />

    <ul
      v-else
      class="space-y-2"
    >
      <li
        v-for="entry in entries"
        :key="entry.id"
        class="glass rounded-xl px-4 py-3 flex items-start gap-3"
      >
        <div
          class="shrink-0 w-12 h-12 rounded-lg bg-ink-800/70 border border-white/5 grid place-items-center overflow-hidden"
        >
          <img
            v-if="entry.reward?.image_url"
            :src="entry.reward.image_url"
            :alt="entry.reward.name"
            class="max-h-10 max-w-[85%] w-auto object-contain"
            loading="lazy"
            decoding="async"
          >
          <span
            v-else
            class="text-xl leading-none"
          >{{ entryEmoji(entry) }}</span>
        </div>

        <div class="flex-1 min-w-0">
          <div class="text-sm font-medium text-slate-100">
            {{ meta[entry.type]?.label ?? entry.type }}
            <span
              v-if="activityTypeLabel(entry)"
              class="text-slate-400 font-normal"
            > · {{ activityTypeLabel(entry) }}</span>
          </div>

          <div
            v-if="showSubject && entry.subject?.nickname"
            class="mt-1 flex flex-wrap items-center gap-x-1.5 gap-y-0.5"
          >
            <span class="text-xs text-slate-500">Гравцю</span>
            <span class="font-display text-sm text-cyan-100 bg-cyan-500/15 border border-cyan-400/35 rounded-md px-2 py-0.5 shadow-[0_0_12px_rgba(34,211,238,0.12)]">
              {{ entry.subject.nickname }}
            </span>
          </div>

          <div
            v-if="entry.type === 'points_award' && (pointsAwardDetails(entry).includeMain || pointsAwardDetails(entry).twinNames.length)"
            class="mt-1.5 flex flex-wrap gap-1.5"
          >
            <span
              v-if="pointsAwardDetails(entry).includeMain"
              class="inline-flex items-center gap-1 rounded-md border border-cyan-400/30 bg-cyan-500/10 px-2 py-0.5 text-[11px] text-cyan-100"
            >
              ★ Основний
            </span>
            <span
              v-for="name in pointsAwardDetails(entry).twinNames"
              :key="name"
              class="inline-flex items-center gap-1 rounded-md border border-slate-600/40 bg-slate-800/50 px-2 py-0.5 text-[11px] text-slate-300"
            >
              ◦ {{ name }}
            </span>
          </div>

          <div
            v-if="isRewardEntry(entry.type) && entry.reward?.name"
            class="mt-1.5 flex items-center gap-2 min-w-0"
          >
            <span class="text-sm text-violet-100 truncate">
              {{ entry.reward.name }}
            </span>
            <span
              v-if="entry.amount != null && entry.amount > 1"
              class="badge text-[10px] shrink-0"
            >
              ×{{ entry.amount }}
            </span>
          </div>

          <p
            v-if="showActor(entry)"
            class="mt-1.5 text-xs text-slate-500"
          >
            {{ actorPrefix(entry.type) }}:
            <span class="text-slate-300">{{ entry.actor!.nickname }}</span>
          </p>

          <div class="text-xs text-slate-500 mt-1">
            {{ format(entry.created_at) }}
            <span v-if="entry.description && entry.type !== 'points_award' && !isRewardEntry(entry.type)">
              · {{ entry.description }}
            </span>
          </div>
        </div>

        <CyberPoints
          v-if="entry.points != null"
          :value="entry.points"
          :sign="isPositive(entry.type) ? '+' : isNegative(entry.type) ? '−' : undefined"
          icon-size="sm"
          class="text-sm font-display shrink-0 pt-0.5"
          :class="isPositive(entry.type)
            ? 'text-emerald-300'
            : isNegative(entry.type) ? 'text-rose-300' : 'text-slate-300'"
        />
        <span
          v-else-if="entry.amount != null && !isRewardEntry(entry.type)"
          class="text-sm font-display text-cyan-200 shrink-0 pt-0.5"
        >
          +{{ entry.amount }}
        </span>
      </li>
    </ul>
  </div>
</template>
