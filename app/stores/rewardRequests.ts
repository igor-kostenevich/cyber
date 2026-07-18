import { defineStore } from 'pinia'
import type { AsyncStateStatus } from '~/types'
import type { RewardRequestView } from '~/types/activity'
import {
  buildRewardQueueMap,
  isActiveRewardRequest,
  type RewardQueuePosition,
} from '~/composables/useRewardRequestQueue'

const SELECT = `
  *,
  profile:profiles!reward_requests_profile_id_fkey(id,nickname,display_name,points_balance,profession),
  reward:rewards(id,name,image_url,stock,price_points)
`

export const useRewardRequestsStore = defineStore('rewardRequests', () => {
  const items = ref<RewardRequestView[]>([])
  const queueTotalsByReward = ref<Record<string, number>>({})
  const status = ref<AsyncStateStatus>('idle')
  const error = ref<string | null>(null)

  const isLoading = computed(() => status.value === 'loading')
  const hasLoaded = computed(() => status.value === 'success' || status.value === 'error')

  const active = computed(() => items.value.filter((r) => isActiveRewardRequest(r.status)))
  const pending = computed(() => active.value)
  const completed = computed(() => items.value.filter((r) => r.status === 'completed'))
  const rejected = computed(() => items.value.filter((r) => r.status === 'rejected'))

  const queueMetaByRequest = ref<Map<string, { position: number, total: number }>>(new Map())

  const queuePositions = computed(() => {
    const fromItems = buildRewardQueueMap(items.value)
    const merged = new Map(fromItems)
    for (const [id, meta] of queueMetaByRequest.value) {
      merged.set(id, meta.position)
    }
    return merged
  })

  function getQueuePosition(requestId: string): number | null {
    return queueMetaByRequest.value.get(requestId)?.position
      ?? queuePositions.value.get(requestId)
      ?? null
  }

  function getQueueTotalForRequest(requestId: string): number | null {
    return queueMetaByRequest.value.get(requestId)?.total ?? null
  }

  async function fetchQueueMeta() {
    const client = useAppSupabaseClient()

    const [posRes, totalsRes] = await Promise.all([
      client.rpc('get_reward_queue_positions'),
      client.rpc('get_reward_queue_totals'),
    ])

    if (posRes.error) throw posRes.error
    if (totalsRes.error) throw totalsRes.error

    const meta = new Map<string, { position: number, total: number }>()
    for (const row of (posRes.data ?? []) as RewardQueuePosition[]) {
      meta.set(row.request_id, {
        position: row.queue_position,
        total: row.queue_total,
      })
    }
    queueMetaByRequest.value = meta

    const totals: Record<string, number> = {}
    for (const row of totalsRes.data ?? []) {
      totals[row.reward_id as string] = row.queue_total as number
    }
    queueTotalsByReward.value = totals
  }

  async function fetchAll() {
    const client = useAppSupabaseClient()
    status.value = 'loading'
    error.value = null
    try {
      const { data, error: err } = await client
        .from('reward_requests')
        .select(SELECT)
        .order('created_at', { ascending: false })

      if (err) throw err
      items.value = (data ?? []) as unknown as RewardRequestView[]
      await fetchQueueMeta()
      status.value = 'success'
    }
    catch (e) {
      error.value = e instanceof Error ? e.message : 'Не вдалося завантажити заявки'
      status.value = 'error'
    }
  }

  async function createRequest(rewardId: string, qty = 1): Promise<void> {
    const client = useAppSupabaseClient()
    const { error: err } = await client.rpc('create_reward_request', {
      p_reward_id: rewardId,
      p_qty: qty,
    })
    if (err) throw err
  }

  async function grant(requestId: string): Promise<void> {
    const client = useAppSupabaseClient()
    const { error: err } = await client.rpc('grant_reward_request', { p_request_id: requestId })
    if (err) throw err
  }

  async function reject(requestId: string): Promise<void> {
    const client = useAppSupabaseClient()
    const { error: err } = await client.rpc('reject_reward_request', { p_request_id: requestId })
    if (err) throw err
  }

  async function cancel(requestId: string): Promise<void> {
    const client = useAppSupabaseClient()
    const { error: err } = await client.rpc('cancel_reward_request', { p_request_id: requestId })
    if (err) throw err
  }

  return {
    items,
    queueTotalsByReward,
    status,
    error,
    isLoading,
    hasLoaded,
    active,
    pending,
    completed,
    rejected,
    queueMetaByRequest,
    queuePositions,
    getQueuePosition,
    getQueueTotalForRequest,
    getQueueTotal: (rewardId: string) => queueTotalsByReward.value[rewardId] ?? 0,
    fetchAll,
    fetchQueueMeta,
    createRequest,
    grant,
    reject,
    cancel,
  }
})
