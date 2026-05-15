import { defineStore } from 'pinia'
import type {
  AsyncStateStatus,
  JoinRequestPayload,
  Participant,
  ParticipantStatus,
} from '~/types'

export const useParticipantsStore = defineStore('participants', () => {
  const items = ref<Participant[]>([])
  const status = ref<AsyncStateStatus>('loading')
  const error = ref<string | null>(null)

  const isLoading = computed(() => status.value === 'loading')
  const hasLoaded = computed(() => status.value === 'success' || status.value === 'error')

  const approved = computed(() =>
    items.value.filter((p) => p.status === 'approved'),
  )
  const pending = computed(() =>
    items.value.filter((p) => p.status === 'pending'),
  )
  const rejected = computed(() =>
    items.value.filter((p) => p.status === 'rejected'),
  )

  function getById(id: string) {
    return items.value.find((p) => p.id === id) ?? null
  }

  async function fetchAll() {
    const client = useAppSupabaseClient()
    status.value = 'loading'
    error.value = null
    try {
      const { data, error: err } = await client
        .from('participants')
        .select('*')
        .order('created_at', { ascending: false })

      if (err) throw err
      items.value = (data ?? []) as Participant[]
      status.value = 'success'
    }
    catch (e) {
      error.value = e instanceof Error ? e.message : 'Не вдалося завантажити учасників'
      status.value = 'error'
    }
  }

  async function requestJoin(payload: JoinRequestPayload): Promise<void> {
    const client = useAppSupabaseClient()
    const nickname = payload.nickname.trim()
    if (!nickname) throw new Error('Нікнейм обовʼязковий')

    const { error: err } = await client.from('participants').insert({
      nickname,
      real_name: payload.real_name.trim() || null,
      comment: (payload.comment ?? '').trim() || null,
      status: 'pending' satisfies ParticipantStatus,
    })

    if (err) {
      console.error('[participants.requestJoin] Supabase error:', err)
      throw err
    }
  }

  async function updateStatus(id: string, newStatus: ParticipantStatus) {
    const client = useAppSupabaseClient()
    const { data, error: err } = await client
      .from('participants')
      .update({ status: newStatus })
      .eq('id', id)
      .select()
      .single()

    if (err) throw err
    if (data) {
      const idx = items.value.findIndex((p) => p.id === id)
      if (idx >= 0) items.value[idx] = data as Participant
    }
  }

  async function updateOne(id: string, patch: Partial<Omit<Participant, 'id' | 'created_at'>>) {
    const client = useAppSupabaseClient()
    const { data, error: err } = await client
      .from('participants')
      .update(patch)
      .eq('id', id)
      .select()
      .single()

    if (err) throw err
    if (data) {
      const idx = items.value.findIndex((p) => p.id === id)
      if (idx >= 0) items.value[idx] = data as Participant
    }
  }

  async function remove(id: string) {
    const client = useAppSupabaseClient()
    const { error: err } = await client.from('participants').delete().eq('id', id)
    if (err) throw err
    items.value = items.value.filter((p) => p.id !== id)
  }

  return {
    items,
    status,
    error,
    isLoading,
    hasLoaded,
    approved,
    pending,
    rejected,
    getById,
    fetchAll,
    requestJoin,
    updateStatus,
    updateOne,
    remove,
  }
})
