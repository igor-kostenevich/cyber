<script setup lang="ts">
import type { LeaderboardRow } from '~/types/activity'

interface Props {
  rows: LeaderboardRow[]
  currentProfileId?: string | null
  loading?: boolean
  error?: string | null
}

const props = withDefaults(defineProps<Props>(), {
  currentProfileId: null,
  loading: false,
  error: null,
})

const { label: roleLabel, badgeClass: roleBadgeClass } = useUserRoleLabel()
const twins = useTwinsStore()

const medal = (rank: number): string | null => {
  if (rank === 1) return '🥇'
  if (rank === 2) return '🥈'
  if (rank === 3) return '🥉'
  return null
}

const rankClass = (rank: number): string => {
  if (rank === 1) return 'text-amber-300'
  if (rank === 2) return 'text-slate-300'
  if (rank === 3) return 'text-orange-300'
  return 'text-slate-500'
}

watch(
  () => props.rows.map((r) => r.profile_id),
  (ids) => {
    if (ids.length) void twins.fetchForProfiles(ids)
  },
  { immediate: true },
)
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
      v-else-if="rows.length === 0"
      title="Рейтинг порожній"
      description="Бали ще не нараховувались."
    />

    <ul
      v-else
      class="space-y-2"
    >
      <li
        v-for="row in rows"
        :key="row.profile_id"
        class="rounded-xl px-3 sm:px-4 py-3 flex items-center gap-3 transition-colors"
        :class="[
          row.profile_id === currentProfileId
            ? 'bg-cyan-500/10 border border-cyan-400/30'
            : 'glass',
          row.rank <= 3 ? 'shadow-glow-sm' : '',
        ]"
      >
        <div class="w-9 shrink-0 text-center font-display text-lg" :class="rankClass(row.rank)">
          <span v-if="medal(row.rank)">{{ medal(row.rank) }}</span>
          <span v-else>{{ row.rank }}</span>
        </div>

        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-2 flex-wrap">
            <ProfessionIcon :profession="row.profession" size="xs" />
            <span class="text-sm text-slate-100 truncate">
              {{ row.nickname }}
              <span
                v-if="row.profile_id === currentProfileId"
                class="text-xs text-cyan-300/80"
              >(ви)</span>
            </span>
            <span
              class="text-[10px] shrink-0"
              :class="roleBadgeClass(row.role)"
            >
              {{ roleLabel(row.role) }}
            </span>
          </div>
          <div class="text-xs text-slate-500 mt-0.5">
            Івентів: {{ row.events_count }}
          </div>
          <ProfileTwinsExpander
            :profile-id="row.profile_id"
            compact
          />
        </div>

        <div class="text-right shrink-0">
          <div class="text-sm font-display text-cyan-100 flex items-center justify-end gap-1">
            <CyberPoints
              :value="row.month_points"
              icon-size="xs"
            />
            <span class="text-xs text-slate-500">/міс</span>
          </div>
          <div class="text-xs text-slate-500 flex items-center justify-end gap-1">
            <span>Всього:</span>
            <CyberPoints
              :value="row.total_points"
              icon-size="xs"
              muted
            />
          </div>
        </div>
      </li>
    </ul>
  </div>
</template>
