import { defineStore } from 'pinia'
import type { AsyncStateStatus } from '~/types'
import type { HistoryEntryView } from '~/types/activity'
import {
  categoryTypes,
  HISTORY_PAGE_SIZE,
  periodStartISO,
  type HistoryCategory,
  type HistoryPeriod,
} from '~/composables/useHistoryFilters'

const SELECT = `
  *,
  actor:profiles!history_actor_id_fkey(nickname),
  subject:profiles!history_profile_id_fkey(nickname),
  reward:rewards(name, image_url)
`

export interface HistoryFetchParams {
  category?: HistoryCategory
  period?: HistoryPeriod
  page?: number
  pageSize?: number
}

export const useHistoryStore = defineStore('history', () => {
  const items = ref<HistoryEntryView[]>([])
  const totalCount = ref(0)
  const status = ref<AsyncStateStatus>('idle')
  const error = ref<string | null>(null)

  const isLoading = computed(() => status.value === 'loading')
  const hasLoaded = computed(() => status.value === 'success' || status.value === 'error')

  /** RLS повертає всю історію (адмін) або лише особисту (гравець). */
  async function fetchPage(params: HistoryFetchParams = {}) {
    const client = useAppSupabaseClient()
    const category = params.category ?? 'all'
    const period = params.period ?? 'all'
    const page = params.page ?? 1
    const pageSize = params.pageSize ?? HISTORY_PAGE_SIZE

    status.value = 'loading'
    error.value = null

    try {
      const types = categoryTypes(category)
      const periodFrom = periodStartISO(period)
      const from = (page - 1) * pageSize
      const to = from + pageSize - 1

      let query = client
        .from('history')
        .select(SELECT, { count: 'exact' })
        .order('created_at', { ascending: false })

      if (types?.length) query = query.in('type', types)
      if (periodFrom) query = query.gte('created_at', periodFrom)

      const { data, error: err, count } = await query.range(from, to)

      if (err) throw err
      items.value = (data ?? []) as unknown as HistoryEntryView[]
      totalCount.value = count ?? 0
      status.value = 'success'
    }
    catch (e) {
      error.value = e instanceof Error ? e.message : 'Не вдалося завантажити історію'
      status.value = 'error'
    }
  }

  /** @deprecated використовуй fetchPage */
  async function fetchAll(limit = 100) {
    await fetchPage({ period: 'all', page: 1, pageSize: limit })
  }

  return {
    items,
    totalCount,
    status,
    error,
    isLoading,
    hasLoaded,
    fetchPage,
    fetchAll,
  }
})
