import { storeToRefs } from 'pinia'
import type { ActivityType } from '~/types/activity'

export interface ActivityTypeConfig {
  type: ActivityType
  label: string
  points: number
  twinBonusEnabled: boolean
  /** Підпис для швидкої кнопки створення ("Нове ГВГ" тощо). */
  quickLabel: string
  /** Tailwind-класи для акценту картки/іконки. */
  accent: string
  emoji: string
}

const ACTIVITY_META: Record<ActivityType, Omit<ActivityTypeConfig, 'points' | 'twinBonusEnabled'>> = {
  gvg: {
    type: 'gvg',
    label: 'ГВГ',
    quickLabel: 'Нове ГВГ',
    accent: 'text-rose-300 border-rose-400/30 bg-rose-500/10',
    emoji: '⚔️',
  },
  rb_boss: {
    type: 'rb_boss',
    label: 'РБ бос',
    quickLabel: 'Новий РБ',
    accent: 'text-violet-300 border-violet-400/30 bg-violet-500/10',
    emoji: '🐉',
  },
  server_boss: {
    type: 'server_boss',
    label: 'Серверний бос',
    quickLabel: 'Новий серверний бос',
    accent: 'text-cyan-300 border-cyan-400/30 bg-cyan-500/10',
    emoji: '👹',
  },
  craft: {
    type: 'craft',
    label: 'Ремесло',
    quickLabel: 'Нове ремесло',
    accent: 'text-emerald-300 border-emerald-400/30 bg-emerald-500/10',
    emoji: '🔨',
  },
}

const ORDER: ActivityType[] = ['gvg', 'rb_boss', 'server_boss', 'craft']

const FALLBACK_POINTS: Record<ActivityType, number> = {
  gvg: 3,
  rb_boss: 2,
  server_boss: 3,
  craft: 1,
}

export function useActivityTypes() {
  const settings = useActivitySettingsStore()
  const { pointsByType } = storeToRefs(settings)

  const list = computed<ActivityTypeConfig[]>(() =>
    ORDER.map((type) => ({
      ...ACTIVITY_META[type],
      points: pointsByType.value[type] ?? FALLBACK_POINTS[type],
      twinBonusEnabled: settings.getTwinBonusEnabled(type),
    })),
  )

  function get(type: ActivityType): ActivityTypeConfig {
    return {
      ...ACTIVITY_META[type],
      points: pointsByType.value[type] ?? FALLBACK_POINTS[type],
      twinBonusEnabled: settings.getTwinBonusEnabled(type),
    }
  }

  function label(type: ActivityType): string {
    return ACTIVITY_META[type]?.label ?? type
  }

  function points(type: ActivityType): number {
    return pointsByType.value[type] ?? FALLBACK_POINTS[type] ?? 0
  }

  return { list, get, label, points }
}
