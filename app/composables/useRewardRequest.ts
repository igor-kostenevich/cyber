import type { RewardRequest } from '~/types/activity'

export function rewardRequestTotalPoints(req: Pick<RewardRequest, 'price_points' | 'quantity'>): number {
  return req.price_points * (req.quantity ?? 1)
}
