import type { AsyncStateStatus } from '~/types'
import type { LeaderboardRow, Profile } from '~/types/activity'

interface ParticipationRow {
  profile_id: string
  points_awarded: number
  activity: { activity_date: string } | { activity_date: string }[] | null
}

function monthStartISO(): string {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-01`
}

export function useLeaderboard() {
  const rows = ref<LeaderboardRow[]>([])
  const status = ref<AsyncStateStatus>('idle')
  const error = ref<string | null>(null)

  const isLoading = computed(() => status.value === 'loading')
  const hasLoaded = computed(() => status.value === 'success' || status.value === 'error')

  async function load() {
    const client = useAppSupabaseClient()
    status.value = 'loading'
    error.value = null
    try {
      const [profilesRes, partsRes] = await Promise.all([
        client
          .from('profiles')
          .select('id,nickname,display_name,points_balance,role')
          .eq('status', 'approved'),
        client
          .from('activity_participants')
          .select('profile_id, points_awarded, activity:activities(activity_date)'),
      ])

      if (profilesRes.error) throw profilesRes.error
      if (partsRes.error) throw partsRes.error

      const profiles = (profilesRes.data ?? []) as Array<
        Pick<Profile, 'id' | 'nickname' | 'display_name' | 'points_balance' | 'role'>
      >
      const parts = (partsRes.data ?? []) as unknown as ParticipationRow[]

      const monthStart = monthStartISO()
      const monthPoints = new Map<string, number>()
      const eventCount = new Map<string, number>()

      for (const p of parts) {
        eventCount.set(p.profile_id, (eventCount.get(p.profile_id) ?? 0) + 1)
        const act = Array.isArray(p.activity) ? p.activity[0] : p.activity
        if (act && act.activity_date >= monthStart) {
          monthPoints.set(
            p.profile_id,
            (monthPoints.get(p.profile_id) ?? 0) + (p.points_awarded ?? 0),
          )
        }
      }

      const mapped: LeaderboardRow[] = profiles
        .map((p) => ({
          profile_id: p.id,
          nickname: p.nickname,
          display_name: p.display_name,
          role: p.role,
          total_points: p.points_balance,
          month_points: monthPoints.get(p.id) ?? 0,
          events_count: eventCount.get(p.id) ?? 0,
          rank: 0,
        }))
        .sort((a, b) => {
          if (b.month_points !== a.month_points) return b.month_points - a.month_points
          if (b.total_points !== a.total_points) return b.total_points - a.total_points
          return a.nickname.localeCompare(b.nickname)
        })
        .map((row, i) => ({ ...row, rank: i + 1 }))

      rows.value = mapped
      status.value = 'success'
    }
    catch (e) {
      error.value = e instanceof Error ? e.message : 'Не вдалося завантажити рейтинг'
      status.value = 'error'
    }
  }

  return { rows, status, error, isLoading, hasLoaded, load }
}
