<script setup lang="ts">
import type { HistoryEntryView, HistoryType } from '~/types/activity'
import { HISTORY_ADMIN_ACTION_TYPES } from '~/composables/useHistoryFilters'

interface Props {
  entries: HistoryEntryView[]
  loading?: boolean
  error?: string | null
  showSubject?: boolean
}

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
  user_approve: { emoji: '✅', label: 'Підтверджено' },
  user_status: { emoji: '🔄', label: 'Зміна статусу' },
  role_change: { emoji: '⭐', label: 'Зміна ролі' },
  reward_update: { emoji: '✏️', label: 'Оновлення нагороди' },
}

const REWARD_HISTORY_TYPES: HistoryType[] = ['reward_grant', 'reward_request', 'points_spend']
const PLAYER_ACTION_TYPES: HistoryType[] = ['user_status', 'user_approve', 'role_change', 'user_register']

const isPositive = (t: HistoryType) => t === 'points_award'
const isNegative = (t: HistoryType) => t === 'points_spend'

function isRewardEntry(type: HistoryType) {
  return REWARD_HISTORY_TYPES.includes(type)
}

function isPlayerAction(type: HistoryType) {
  return PLAYER_ACTION_TYPES.includes(type)
}

function showActor(entry: HistoryEntryView): boolean {
  if (!entry.actor?.nickname) return false
  return HISTORY_ADMIN_ACTION_TYPES.includes(entry.type)
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

interface SingleItem {
  kind: 'single'
  entry: HistoryEntryView
}

interface GroupItem {
  kind: 'group'
  activityId: string
  entries: HistoryEntryView[]
  expanded: boolean
}

type DisplayItem = SingleItem | GroupItem

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  error: null,
  showSubject: false,
})
const expandedGroups = ref<Set<string>>(new Set())

function toggleGroup(activityId: string) {
  if (expandedGroups.value.has(activityId)) {
    expandedGroups.value.delete(activityId)
  }
  else {
    expandedGroups.value.add(activityId)
  }
  expandedGroups.value = new Set(expandedGroups.value)
}

const displayItems = computed<DisplayItem[]>(() => {
  const result: DisplayItem[] = []
  const grouped = new Map<string, HistoryEntryView[]>()

  for (const entry of props.entries) {
    if (entry.type === 'points_award' && entry.activity_id) {
      const key = entry.activity_id
      if (!grouped.has(key)) grouped.set(key, [])
      grouped.get(key)!.push(entry)
    }
    else {
      result.push({ kind: 'single', entry })
    }
  }

  for (const [activityId, entries] of grouped) {
    if (entries.length === 1) {
      result.push({ kind: 'single', entry: entries[0]! })
    }
    else {
      result.push({
        kind: 'group',
        activityId,
        entries,
        expanded: expandedGroups.value.has(activityId),
      })
    }
  }

  return result.sort((a, b) => {
    const dateA = a.kind === 'single' ? a.entry.created_at : a.entries[0]!.created_at
    const dateB = b.kind === 'single' ? b.entry.created_at : b.entries[0]!.created_at
    return dateB.localeCompare(dateA)
  })
})

function groupLabel(group: GroupItem): string | null {
  const first = group.entries[0]
  if (!first?.description) return null
  const parsed = parsePointsAwardDescription(first.description)
  if (!parsed.activityType) return null
  return activityLabel(parsed.activityType as Parameters<typeof activityLabel>[0])
}

function groupTotalPoints(group: GroupItem): number {
  return group.entries.reduce((sum, e) => sum + (e.points ?? 0), 0)
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
      v-else-if="displayItems.length === 0"
      title="Нічого не знайдено"
      description="Спробуйте інший фільтр або період."
    />

    <ul
      v-else
      class="space-y-2"
    >
      <li
        v-for="(item, idx) in displayItems"
        :key="idx"
      >
        <!-- Grouped points_award -->
        <div
          v-if="item.kind === 'group'"
          class="glass rounded-xl overflow-hidden"
        >
          <button
            class="w-full flex items-center gap-3 px-4 py-3 hover:bg-white/[0.03] transition-colors text-left"
            @click="toggleGroup(item.activityId)"
          >
            <div class="shrink-0 w-12 h-12 rounded-lg bg-ink-800/70 border border-white/5 grid place-items-center text-xl">
              ➕
            </div>

            <div class="flex-1 min-w-0">
              <div class="text-sm font-medium text-slate-100">
                {{ meta.points_award.label }}
                <span
                  v-if="groupLabel(item)"
                  class="text-slate-400 font-normal"
                > · {{ groupLabel(item) }}</span>
              </div>
              <div class="text-xs text-slate-500 mt-0.5">
                {{ format(item.entries[0]!.created_at) }}
                <span class="text-slate-600 mx-1">·</span>
                <span class="text-slate-400">{{ item.entries.length }} гравців</span>
              </div>
            </div>

            <div class="flex items-center gap-3 shrink-0">
              <CyberPoints
                :value="groupTotalPoints(item)"
                sign="+"
                icon-size="sm"
                class="text-sm font-display text-emerald-300"
              />
              <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 20 20"
                fill="currentColor"
                class="h-4 w-4 text-slate-500 transition-transform duration-200"
                :class="item.expanded ? 'rotate-180' : ''"
              >
                <path
                  fill-rule="evenodd"
                  d="M5.22 8.22a.75.75 0 0 1 1.06 0L10 11.94l3.72-3.72a.75.75 0 1 1 1.06 1.06l-4.25 4.25a.75.75 0 0 1-1.06 0L5.22 9.28a.75.75 0 0 1 0-1.06Z"
                  clip-rule="evenodd"
                />
              </svg>
            </div>
          </button>

          <Transition
            enter-active-class="transition-all duration-200 origin-top"
            enter-from-class="opacity-0 max-h-0"
            enter-to-class="opacity-100 max-h-[40rem]"
            leave-active-class="transition-all duration-150 origin-top"
            leave-from-class="opacity-100 max-h-[40rem]"
            leave-to-class="opacity-0 max-h-0"
          >
            <ul
              v-if="item.expanded"
              class="border-t border-white/5 overflow-hidden"
            >
              <li
                v-for="entry in item.entries"
                :key="entry.id"
                class="flex items-center gap-3 px-4 py-2.5 border-b border-white/[0.04] last:border-0"
              >
                <div class="flex-1 min-w-0">
                  <div
                    v-if="entry.subject?.nickname"
                    class="flex items-center gap-1.5"
                  >
                    <ProfessionIcon :profession="entry.subject.profession" size="xs" />
                    <span class="font-display text-sm text-cyan-100 bg-cyan-500/15 border border-cyan-400/30 rounded-md px-2 py-0.5">
                      {{ entry.subject.nickname }}
                    </span>
                  </div>
                  <div
                    v-if="pointsAwardDetails(entry).includeMain || pointsAwardDetails(entry).twinNames.length"
                    class="mt-1 flex flex-wrap gap-1"
                  >
                    <span
                      v-if="pointsAwardDetails(entry).includeMain"
                      class="inline-flex items-center gap-1 rounded-md border border-cyan-400/30 bg-cyan-500/10 px-1.5 py-0.5 text-[10px] text-cyan-100"
                    >★ Основний</span>
                    <span
                      v-for="name in pointsAwardDetails(entry).twinNames"
                      :key="name"
                      class="inline-flex items-center gap-1 rounded-md border border-slate-600/40 bg-slate-800/50 px-1.5 py-0.5 text-[10px] text-slate-300"
                    >◦ {{ name }}</span>
                  </div>
                </div>
                <CyberPoints
                  :value="entry.points ?? 0"
                  sign="+"
                  icon-size="xs"
                  class="text-sm font-display text-emerald-300 shrink-0"
                />
              </li>
            </ul>
          </Transition>
        </div>

        <!-- Single entry -->
        <div
          v-else
          class="glass rounded-xl px-4 py-3 flex items-start gap-3"
        >
          <div class="shrink-0 w-12 h-12 rounded-lg bg-ink-800/70 border border-white/5 grid place-items-center overflow-hidden">
            <img
              v-if="item.entry.reward?.image_url"
              :src="item.entry.reward.image_url"
              :alt="item.entry.reward.name"
              class="max-h-10 max-w-[85%] w-auto object-contain"
              loading="lazy"
              decoding="async"
            >
            <span
              v-else
              class="text-xl leading-none"
            >{{ entryEmoji(item.entry) }}</span>
          </div>

          <div class="flex-1 min-w-0">
            <div class="text-sm font-medium text-slate-100">
              {{ meta[item.entry.type]?.label ?? item.entry.type }}
              <span
                v-if="activityTypeLabel(item.entry)"
                class="text-slate-400 font-normal"
              > · {{ activityTypeLabel(item.entry) }}</span>
            </div>

            <!-- Player action: show description as main info -->
            <div
              v-if="isPlayerAction(item.entry.type) && item.entry.description"
              class="mt-1 inline-flex items-center gap-1.5 rounded-md border border-slate-600/40 bg-slate-800/60 px-2 py-0.5"
            >
              <span class="text-sm text-slate-200">{{ item.entry.description }}</span>
            </div>

            <!-- Subject (admin view, non-player-action) -->
            <div
              v-else-if="showSubject && item.entry.subject?.nickname && !isPlayerAction(item.entry.type)"
              class="mt-1 flex flex-wrap items-center gap-x-1.5 gap-y-0.5"
            >
              <span class="text-xs text-slate-500">Гравцю</span>
              <ProfessionIcon :profession="item.entry.subject.profession" size="xs" />
              <span class="font-display text-sm text-cyan-100 bg-cyan-500/15 border border-cyan-400/35 rounded-md px-2 py-0.5 shadow-[0_0_12px_rgba(34,211,238,0.12)]">
                {{ item.entry.subject.nickname }}
              </span>
            </div>

            <div
              v-if="item.entry.type === 'points_award' && (pointsAwardDetails(item.entry).includeMain || pointsAwardDetails(item.entry).twinNames.length)"
              class="mt-1.5 flex flex-wrap gap-1.5"
            >
              <span
                v-if="pointsAwardDetails(item.entry).includeMain"
                class="inline-flex items-center gap-1 rounded-md border border-cyan-400/30 bg-cyan-500/10 px-2 py-0.5 text-[11px] text-cyan-100"
              >
                ★ Основний
              </span>
              <span
                v-for="name in pointsAwardDetails(item.entry).twinNames"
                :key="name"
                class="inline-flex items-center gap-1 rounded-md border border-slate-600/40 bg-slate-800/50 px-2 py-0.5 text-[11px] text-slate-300"
              >
                ◦ {{ name }}
              </span>
            </div>

            <div
              v-if="isRewardEntry(item.entry.type) && item.entry.reward?.name"
              class="mt-1.5 flex items-center gap-2 min-w-0"
            >
              <span class="text-sm text-violet-100 truncate">{{ item.entry.reward.name }}</span>
              <span
                v-if="item.entry.amount != null && item.entry.amount > 1"
                class="badge text-[10px] shrink-0"
              >×{{ item.entry.amount }}</span>
            </div>

            <p
              v-if="showActor(item.entry)"
              class="mt-1.5 text-xs text-slate-500"
            >
              Виконав: <span class="text-slate-300">{{ item.entry.actor!.nickname }}</span>
            </p>

            <div class="text-xs text-slate-500 mt-1">
              {{ format(item.entry.created_at) }}
              <template v-if="item.entry.description && item.entry.type !== 'points_award' && !isRewardEntry(item.entry.type) && !isPlayerAction(item.entry.type)">
                <span class="mx-1">·</span>{{ item.entry.description }}
              </template>
            </div>
          </div>

          <CyberPoints
            v-if="item.entry.points != null"
            :value="item.entry.points"
            :sign="isPositive(item.entry.type) ? '+' : isNegative(item.entry.type) ? '−' : undefined"
            icon-size="sm"
            class="text-sm font-display shrink-0 pt-0.5"
            :class="isPositive(item.entry.type)
              ? 'text-emerald-300'
              : isNegative(item.entry.type) ? 'text-rose-300' : 'text-slate-300'"
          />
          <span
            v-else-if="item.entry.amount != null && !isRewardEntry(item.entry.type)"
            class="text-sm font-display text-cyan-200 shrink-0 pt-0.5"
          >
            +{{ item.entry.amount }}
          </span>
        </div>
      </li>
    </ul>
  </div>
</template>
