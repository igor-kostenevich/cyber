import type { RewardRequest, RewardRequestStatus } from '~/types/activity'

export const ACTIVE_REWARD_REQUEST_STATUSES = ['pending', 'waiting'] as const satisfies readonly RewardRequestStatus[]

export type ActiveRewardRequestStatus = (typeof ACTIVE_REWARD_REQUEST_STATUSES)[number]

export interface RewardQueuePosition {
  request_id: string
  reward_id: string
  queue_position: number
  queue_total: number
}

export function isActiveRewardRequest(status: RewardRequestStatus): boolean {
  return (ACTIVE_REWARD_REQUEST_STATUSES as readonly string[]).includes(status)
}

export function buildRewardQueueMap(
  requests: Pick<RewardRequest, 'id' | 'reward_id' | 'status' | 'created_at'>[],
): Map<string, number> {
  const byReward = new Map<string, Array<{ id: string, created_at: string }>>()

  for (const req of requests) {
    if (!isActiveRewardRequest(req.status)) continue
    const list = byReward.get(req.reward_id) ?? []
    list.push({ id: req.id, created_at: req.created_at })
    byReward.set(req.reward_id, list)
  }

  const positions = new Map<string, number>()
  for (const list of byReward.values()) {
    list.sort((a, b) => a.created_at.localeCompare(b.created_at) || a.id.localeCompare(b.id))
    list.forEach((item, index) => positions.set(item.id, index + 1))
  }

  return positions
}

export function rewardRequestStatusMeta(
  status: RewardRequestStatus,
  opts?: { queuePosition?: number | null, inStock?: boolean },
): { label: string, cls: string } {
  if (status === 'waiting') {
    const pos = opts?.queuePosition
    return {
      label: pos ? `Черга #${pos}` : 'Очікування складу',
      cls: 'badge-warn',
    }
  }

  if (status === 'pending') {
    if (opts?.inStock === false) {
      return { label: 'Очікує склад', cls: 'badge-warn' }
    }
    return { label: 'Готово до видачі', cls: 'badge-info' }
  }

  if (status === 'completed') return { label: 'Видано', cls: 'badge-ok' }
  if (status === 'rejected') return { label: 'Відхилено', cls: 'badge-err' }

  return { label: status, cls: 'badge-info' }
}
