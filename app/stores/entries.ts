import { defineStore } from 'pinia'
import type { AsyncStateStatus, EntryFormPayload, SealEntry } from '~/types'

export const useEntriesStore = defineStore('entries', () => {
  const items = ref<SealEntry[]>([])
  const status = ref<AsyncStateStatus>('loading')
  const error = ref<string | null>(null)

  const isLoading = computed(() => status.value === 'loading')
  const hasLoaded = computed(() => status.value === 'success' || status.value === 'error')

  const byParticipant = computed(() => {
    const map = new Map<string, SealEntry[]>()
    for (const e of items.value) {
      const list = map.get(e.participant_id) ?? []
      list.push(e)
      map.set(e.participant_id, list)
    }
    for (const list of map.values()) {
      list.sort((a, b) => (a.entry_date < b.entry_date ? 1 : -1))
    }
    return map
  })

  function forParticipant(participantId: string): SealEntry[] {
    return byParticipant.value.get(participantId) ?? []
  }

  async function fetchAll() {
    const client = useAppSupabaseClient()
    status.value = 'loading'
    error.value = null
    try {
      const { data, error: err } = await client
        .from('seal_entries')
        .select('*')
        .order('entry_date', { ascending: false })

      if (err) throw err
      items.value = (data ?? []) as SealEntry[]
      status.value = 'success'
    }
    catch (e) {
      error.value = e instanceof Error ? e.message : 'Не вдалося завантажити записи'
      status.value = 'error'
    }
  }

  async function create(payload: EntryFormPayload) {
    const client = useAppSupabaseClient()
    const insertPayload = {
      participant_id: payload.participant_id,
      entry_date: payload.entry_date,
      seals_count: payload.seals_count,
      closed_count: payload.closed_count,
      comment: payload.comment.trim() || null,
    }

    const { data, error: err } = await client
      .from('seal_entries')
      .insert(insertPayload)
      .select()
      .single()

    if (err) throw err
    if (data) items.value = [data as SealEntry, ...items.value]
  }

  async function update(id: string, patch: Partial<Omit<SealEntry, 'id' | 'created_at'>>) {
    const client = useAppSupabaseClient()
    const { data, error: err } = await client
      .from('seal_entries')
      .update(patch)
      .eq('id', id)
      .select()
      .single()

    if (err) throw err
    if (data) {
      const idx = items.value.findIndex((e) => e.id === id)
      if (idx >= 0) items.value[idx] = data as SealEntry
    }
  }

  async function remove(id: string) {
    const client = useAppSupabaseClient()
    const { error: err } = await client.from('seal_entries').delete().eq('id', id)
    if (err) throw err
    items.value = items.value.filter((e) => e.id !== id)
  }

  return {
    items,
    status,
    error,
    isLoading,
    hasLoaded,
    byParticipant,
    forParticipant,
    fetchAll,
    create,
    update,
    remove,
  }
})
