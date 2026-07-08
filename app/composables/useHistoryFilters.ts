import type { HistoryType } from '~/types/activity'

export type HistoryCategory = 'all' | 'rewards' | 'points' | 'players' | 'warehouse'
export type HistoryPeriod = 'today' | '7d' | '30d' | 'all'

export const HISTORY_PAGE_SIZE = 20

export const HISTORY_CATEGORIES: Array<{
  id: HistoryCategory
  label: string
  types?: HistoryType[]
}> = [
  { id: 'all', label: 'Усе' },
  {
    id: 'rewards',
    label: 'Нагороди',
    types: ['reward_grant', 'reward_request', 'points_spend'],
  },
  {
    id: 'points',
    label: 'Cyber-кредити',
    types: ['points_award'],
  },
  {
    id: 'players',
    label: 'Гравці',
    types: ['user_register', 'user_approve', 'user_status', 'role_change'],
  },
  {
    id: 'warehouse',
    label: 'Склад і система',
    types: ['stock_add', 'reward_update'],
  },
]

export const HISTORY_PERIODS: Array<{ id: HistoryPeriod, label: string }> = [
  { id: 'today', label: 'Сьогодні' },
  { id: '7d', label: '7 днів' },
  { id: '30d', label: '30 днів' },
  { id: 'all', label: 'Весь час' },
]

/** Типи, де actor — адміністратор (показуємо в UI). */
export const HISTORY_ADMIN_ACTION_TYPES: HistoryType[] = [
  'reward_grant',
  'points_award',
  'points_spend',
  'stock_add',
  'reward_update',
  'user_approve',
  'user_status',
  'role_change',
]

export function periodStartISO(period: HistoryPeriod): string | null {
  if (period === 'all') return null

  const d = new Date()
  if (period === 'today') {
    d.setHours(0, 0, 0, 0)
  }
  else if (period === '7d') {
    d.setDate(d.getDate() - 7)
  }
  else if (period === '30d') {
    d.setDate(d.getDate() - 30)
  }
  return d.toISOString()
}

export function categoryTypes(category: HistoryCategory): HistoryType[] | null {
  const item = HISTORY_CATEGORIES.find((c) => c.id === category)
  return item?.types ?? null
}
