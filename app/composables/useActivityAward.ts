import type { ActivityAwardParticipant } from '~/types/activity'

export function calculateParticipantPoints(
  basePoints: number,
  participant: Pick<ActivityAwardParticipant, 'includeMain' | 'twinIds'>,
): number {
  const base = roundPoints(basePoints)
  let total = 0

  if (participant.includeMain) total += base

  const twinCount = participant.twinIds?.length ?? 0
  if (twinCount > 0) {
    total += roundPoints(base * 0.2) * twinCount
  }

  return roundPoints(total)
}

export interface ParsedPointsAwardDescription {
  activityType: string | null
  includeMain: boolean
  twinNames: string[]
  extraText: string | null
}

export function parsePointsAwardDescription(
  description: string | null,
): ParsedPointsAwardDescription {
  if (!description) {
    return { activityType: null, includeMain: false, twinNames: [], extraText: null }
  }

  const parts = description.split(' · ')
  const activityType = parts[0]?.trim() || null
  let includeMain = false
  const twinNames: string[] = []
  const extra: string[] = []

  for (let i = 1; i < parts.length; i++) {
    const part = parts[i]?.trim()
    if (!part) continue

    if (part === 'основний') {
      includeMain = true
    }
    else if (part.startsWith('твінки: ')) {
      twinNames.push(...part.slice(8).split(',').map((s) => s.trim()).filter(Boolean))
    }
    else if (part.startsWith('твінк: ')) {
      twinNames.push(part.slice(7).trim())
    }
    else {
      extra.push(part)
    }
  }

  return {
    activityType,
    includeMain,
    twinNames,
    extraText: extra.length ? extra.join(' · ') : null,
  }
}

export function useActivityAward() {
  return { calculateParticipantPoints, parsePointsAwardDescription }
}
