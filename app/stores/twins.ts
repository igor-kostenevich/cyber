import { defineStore } from 'pinia'
import type { AsyncStateStatus } from '~/types'
import type { ProfileTwin, TwinDraft } from '~/types/activity'

export const useTwinsStore = defineStore('twins', () => {
  const byProfileId = ref<Record<string, ProfileTwin[]>>({})
  const mine = ref<ProfileTwin[]>([])
  const status = ref<AsyncStateStatus>('idle')
  const error = ref<string | null>(null)

  const isLoading = computed(() => status.value === 'loading')

  function getForProfile(profileId: string): ProfileTwin[] {
    return byProfileId.value[profileId] ?? []
  }

  function currentProfileId(): string | null {
    const profile = useProfileStore()
    const auth = useAuthStore()
    return profile.data?.id ?? auth.user?.id ?? null
  }

  async function fetchForProfiles(profileIds: string[]) {
    if (profileIds.length === 0) return

    const client = useAppSupabaseClient()
    const { data, error: err } = await client
      .from('profile_twins')
      .select('*')
      .in('profile_id', profileIds)
      .order('created_at', { ascending: true })

    if (err) throw err

    const grouped: Record<string, ProfileTwin[]> = {}
    for (const id of profileIds) grouped[id] = []

    for (const row of (data ?? []) as ProfileTwin[]) {
      const list = grouped[row.profile_id]
      if (list) list.push(row)
    }

    byProfileId.value = { ...byProfileId.value, ...grouped }
  }

  async function fetchMine() {
    const profileId = currentProfileId()
    if (!profileId) {
      mine.value = []
      return
    }

    status.value = 'loading'
    error.value = null
    try {
      await fetchForProfiles([profileId])
      mine.value = getForProfile(profileId)
      status.value = 'success'
    }
    catch (e) {
      error.value = e instanceof Error ? e.message : 'Не вдалося завантажити твінків'
      status.value = 'error'
    }
  }

  async function add(nickname: string, profession?: number | null): Promise<void> {
    const client = useAppSupabaseClient()
    const profile = useProfileStore()
    const profileId = currentProfileId()
    if (!profileId) throw new Error('Увійдіть у акаунт')

    const trimmed = nickname.trim()
    if (trimmed.length < 2) throw new Error('Нік твінка занадто короткий')

    if (
      profile.data?.nickname
      && trimmed.toLowerCase() === profile.data.nickname.toLowerCase()
    ) {
      throw new Error('Твінк не може збігатися з основним ніком')
    }

    const { error: insertErr } = await client.from('profile_twins').insert({
      profile_id: profileId,
      nickname: trimmed,
      profession: profession ?? null,
    })

    if (insertErr) {
      if (insertErr.code === '23505') throw new Error('Такий твінк уже додано')
      throw insertErr
    }

    await fetchForProfiles([profileId])
    mine.value = getForProfile(profileId)
  }

  async function addMany(twins: TwinDraft[] | string[]): Promise<void> {
    for (const t of twins) {
      if (typeof t === 'string') {
        const trimmed = t.trim()
        if (trimmed) await add(trimmed)
      }
      else {
        const trimmed = t.nickname.trim()
        if (trimmed) await add(trimmed, t.profession)
      }
    }
  }

  async function updateProfession(twinId: string, profession: number | null): Promise<void> {
    const client = useAppSupabaseClient()
    const profileId = currentProfileId()
    if (!profileId) throw new Error('Увійдіть у акаунт')

    const { error: err } = await client
      .from('profile_twins')
      .update({ profession })
      .eq('id', twinId)
      .eq('profile_id', profileId)

    if (err) throw err

    await fetchForProfiles([profileId])
    mine.value = getForProfile(profileId)
  }

  async function adminUpdateTwinProfession(twinId: string, profession: number | null, ownerProfileId: string): Promise<void> {
    const client = useAppSupabaseClient()
    const { error: err } = await client.rpc('admin_set_twin_profession', {
      p_twin_id: twinId,
      p_profession: profession,
    })
    if (err) throw err
    await fetchForProfiles([ownerProfileId])
  }

  async function remove(twinId: string): Promise<void> {
    const client = useAppSupabaseClient()
    const profileId = currentProfileId()
    if (!profileId) throw new Error('Увійдіть у акаунт')

    const { error: deleteErr } = await client
      .from('profile_twins')
      .delete()
      .eq('id', twinId)
      .eq('profile_id', profileId)

    if (deleteErr) throw deleteErr

    await fetchForProfiles([profileId])
    mine.value = getForProfile(profileId)
  }

  return {
    byProfileId,
    mine,
    status,
    error,
    isLoading,
    getForProfile,
    fetchForProfiles,
    fetchMine,
    add,
    addMany,
    updateProfession,
    adminUpdateTwinProfession,
    remove,
  }
})
