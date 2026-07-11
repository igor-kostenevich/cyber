import { defineStore } from 'pinia'
import type { AsyncStateStatus } from '~/types'
import type { Profile, RegisterPayload } from '~/types/activity'

export const useProfileStore = defineStore('profile', () => {
  const data = ref<Profile | null>(null)
  const status = ref<AsyncStateStatus>('idle')
  const error = ref<string | null>(null)
  const loaded = ref(false)

  const isLoading = computed(() => status.value === 'loading')
  const role = computed(() => data.value?.role ?? null)
  const balance = computed(() => data.value?.points_balance ?? 0)
  const isApproved = computed(() => data.value?.status === 'approved')
  const isAdmin = computed(
    () => data.value?.status === 'approved'
      && (data.value?.role === 'admin' || data.value?.role === 'super_admin'),
  )
  const isSuperAdmin = computed(
    () => data.value?.status === 'approved' && data.value?.role === 'super_admin',
  )

  async function fetchMine(userId?: string): Promise<Profile | null> {
    const client = useAppSupabaseClient()
    status.value = 'loading'
    error.value = null
    try {
      // id відомий із сесії — не робимо зайвий мережевий getUser().
      let uid = userId
      if (!uid) {
        const { data: auth } = await client.auth.getUser()
        uid = auth.user?.id
      }
      if (!uid) {
        data.value = null
        loaded.value = true
        status.value = 'success'
        return null
      }

      const { data: row, error: err } = await client
        .from('profiles')
        .select('*')
        .eq('id', uid)
        .maybeSingle()

      if (err) throw err
      data.value = (row as Profile) ?? null
      loaded.value = true
      status.value = 'success'
      return data.value
    }
    catch (e) {
      error.value = e instanceof Error ? e.message : 'Не вдалося завантажити профіль'
      status.value = 'error'
      return null
    }
  }

  async function register(payload: RegisterPayload): Promise<void> {
    const client = useAppSupabaseClient()
    const { toEmail } = useNicknameEmail()

    const nickname = payload.nickname.trim()
    if (!nickname) throw new Error('Введіть нік')
    if (payload.password.length < 6) throw new Error('Пароль має містити щонайменше 6 символів')

    status.value = 'loading'
    error.value = null
    try {
      const { error: err } = await client.auth.signUp({
        email: toEmail(nickname),
        password: payload.password,
        options: {
          data: {
            nickname,
            display_name: payload.display_name?.trim() || null,
            comment: payload.comment?.trim() || null,
          },
        },
      })
      if (err) throw err
      // Профіль створюється тригером handle_new_user(); підвантажуємо його.
      await fetchMine()

      const twinNicks = (payload.twins ?? [])
        .map((t) => t.trim())
        .filter(Boolean)
      if (twinNicks.length > 0) {
        await useTwinsStore().addMany(twinNicks)
      }

      status.value = 'success'
    }
    catch (e) {
      error.value = e instanceof Error ? e.message : 'Не вдалося зареєструватися'
      status.value = 'error'
      throw e
    }
  }

  async function updateDisplayName(newName: string): Promise<void> {
    const client = useAppSupabaseClient()
    const trimmed = newName.trim()
    if (!trimmed) throw new Error('Імʼя не може бути порожнім')
    if (!data.value) throw new Error('Профіль не завантажено')

    const { error: err } = await client.rpc('update_display_name', {
      p_display_name: trimmed,
    })
    if (err) throw err
    data.value = { ...data.value, display_name: trimmed }
  }

  function clear() {
    data.value = null
    loaded.value = false
    status.value = 'idle'
    error.value = null
  }

  return {
    data,
    status,
    error,
    loaded,
    isLoading,
    role,
    balance,
    isApproved,
    isAdmin,
    isSuperAdmin,
    fetchMine,
    register,
    updateDisplayName,
    clear,
  }
})
