import { defineStore } from 'pinia'
import type { AsyncStateStatus } from '~/types'
import type { Activity, ActivityAwardParticipant, ActivityType } from '~/types/activity'

export const useActivitiesStore = defineStore('activities', () => {
  const items = ref<Activity[]>([])
  const status = ref<AsyncStateStatus>('idle')
  const error = ref<string | null>(null)

  const isLoading = computed(() => status.value === 'loading')
  const hasLoaded = computed(() => status.value === 'success' || status.value === 'error')

  async function fetchRecent(limit = 20) {
    const client = useAppSupabaseClient()
    status.value = 'loading'
    error.value = null
    try {
      const { data, error: err } = await client
        .from('activities')
        .select('*')
        .order('activity_date', { ascending: false })
        .order('created_at', { ascending: false })
        .limit(limit)

      if (err) throw err
      items.value = (data ?? []) as Activity[]
      status.value = 'success'
    }
    catch (e) {
      error.value = e instanceof Error ? e.message : 'Не вдалося завантажити активності'
      status.value = 'error'
    }
  }

  async function create(params: {
    type: ActivityType
    date: string
    description?: string
    participants: ActivityAwardParticipant[]
    points: number
  }): Promise<string> {
    const client = useAppSupabaseClient()
    const awards = params.participants.map((p) => ({
      profile_id: p.profileId,
      include_main: p.includeMain,
      twin_ids: p.twinIds,
    }))

    const { data, error: err } = await client.rpc('award_activity_points', {
      p_type: params.type,
      p_date: params.date,
      p_description: params.description ?? null,
      p_profile_ids: null,
      p_points: roundPoints(params.points),
      p_awards: awards,
    })
    if (err) throw err
    return data as string
  }

  return {
    items,
    status,
    error,
    isLoading,
    hasLoaded,
    fetchRecent,
    create,
  }
})
