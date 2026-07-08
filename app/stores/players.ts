import { defineStore } from 'pinia'
import type { AsyncStateStatus } from '~/types'
import type { Profile, UserRole, UserStatus } from '~/types/activity'

export const usePlayersStore = defineStore('players', () => {
  const items = ref<Profile[]>([])
  const status = ref<AsyncStateStatus>('idle')
  const error = ref<string | null>(null)

  const isLoading = computed(() => status.value === 'loading')
  const hasLoaded = computed(() => status.value === 'success' || status.value === 'error')

  const pending = computed(() => items.value.filter((p) => p.status === 'pending'))
  const approved = computed(() => items.value.filter((p) => p.status === 'approved'))
  const blocked = computed(() => items.value.filter((p) => p.status === 'blocked'))

  async function fetchAll() {
    const client = useAppSupabaseClient()
    status.value = 'loading'
    error.value = null
    try {
      const { data, error: err } = await client
        .from('profiles')
        .select('*')
        .order('created_at', { ascending: false })

      if (err) throw err
      items.value = (data ?? []) as Profile[]
      status.value = 'success'
    }
    catch (e) {
      error.value = e instanceof Error ? e.message : 'Не вдалося завантажити гравців'
      status.value = 'error'
    }
  }

  async function refreshOne(id: string) {
    const client = useAppSupabaseClient()
    const { data } = await client.from('profiles').select('*').eq('id', id).maybeSingle()
    if (data) {
      const idx = items.value.findIndex((p) => p.id === id)
      if (idx >= 0) items.value[idx] = data as Profile
    }
  }

  async function setStatus(id: string, newStatus: UserStatus) {
    const client = useAppSupabaseClient()
    const { error: err } = await client.rpc('set_user_status', {
      p_profile_id: id,
      p_status: newStatus,
    })
    if (err) throw err
    await refreshOne(id)
  }

  async function setRole(id: string, newRole: UserRole) {
    const client = useAppSupabaseClient()
    const { error: err } = await client.rpc('set_user_role', {
      p_profile_id: id,
      p_role: newRole,
    })
    if (err) throw err
    await refreshOne(id)
  }

  return {
    items,
    status,
    error,
    isLoading,
    hasLoaded,
    pending,
    approved,
    blocked,
    fetchAll,
    refreshOne,
    setStatus,
    setRole,
  }
})
