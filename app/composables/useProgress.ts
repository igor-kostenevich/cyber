import type { ProgressSummary } from '~/types'

export function useProgress() {
  const settings = useSettingsStore()
  const participants = useParticipantsStore()
  const entries = useEntriesStore()

  const isLoading = computed(
    () => !settings.hasLoaded || !participants.hasLoaded || !entries.hasLoaded,
  )

  const summary = computed<ProgressSummary>(() => {
    const target = settings.data?.target_seals ?? 0
    const approvedIds = new Set(participants.approved.map((p) => p.id))
    const approvedEntries = entries.items.filter((e) =>
      approvedIds.has(e.participant_id),
    )

    const collected = approvedEntries.reduce(
      (sum, e) => sum + (e.seals_count ?? 0),
      0,
    )
    const remaining = Math.max(0, target - collected)
    const percent = target > 0 ? Math.min(100, (collected / target) * 100) : 0

    const debtByParticipant = new Map<string, number>()
    for (const e of approvedEntries) {
      const debt = (e.seals_count ?? 0) - (e.closed_count ?? 0)
      debtByParticipant.set(
        e.participant_id,
        (debtByParticipant.get(e.participant_id) ?? 0) + debt,
      )
    }
    let withDebtCount = 0
    for (const value of debtByParticipant.values()) {
      if (value > 0) withDebtCount += 1
    }

    return {
      target,
      collected,
      remaining,
      percent,
      approvedCount: participants.approved.length,
      withDebtCount,
    }
  })

  return { summary, isLoading }
}
