import type { MaybeRefOrGetter } from 'vue'
import type { ParticipantStats } from '~/types'

export function useParticipantStats(participantId: MaybeRefOrGetter<string>) {
  const entries = useEntriesStore()

  const stats = computed<ParticipantStats>(() => {
    const id = toValue(participantId)
    const list = entries.forParticipant(id)

    const total = list.reduce((sum, e) => sum + (e.seals_count ?? 0), 0)
    const closed = list.reduce((sum, e) => sum + (e.closed_count ?? 0), 0)
    const unclosed = Math.max(0, total - closed)
    const lastEntryDate = list[0]?.entry_date ?? null

    return {
      total,
      closed,
      unclosed,
      entriesCount: list.length,
      lastEntryDate,
    }
  })

  return { stats }
}
