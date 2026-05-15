import { defineStore } from 'pinia'
import type { AuthUser, AsyncStateStatus } from '~/types'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<AuthUser | null>(null)
  const status = ref<AsyncStateStatus>('idle')
  const error = ref<string | null>(null)
  const initialized = ref(false)

  const isAuthenticated = computed(() => user.value !== null)
  const isLoading = computed(() => status.value === 'loading')

  async function init() {
    if (initialized.value) return
    initialized.value = true

    if (import.meta.server) return

    const client = useAppSupabaseClient()
    status.value = 'loading'
    try {
      const { data, error: err } = await client.auth.getSession()
      if (err) throw err
      const sessionUser = data.session?.user
      user.value = sessionUser
        ? { id: sessionUser.id, email: sessionUser.email ?? null }
        : null
      status.value = 'success'
    }
    catch (e) {
      error.value = e instanceof Error ? e.message : 'Помилка авторизації'
      status.value = 'error'
    }

    client.auth.onAuthStateChange((_event, session) => {
      const sessionUser = session?.user
      user.value = sessionUser
        ? { id: sessionUser.id, email: sessionUser.email ?? null }
        : null
    })
  }

  async function login(email: string, password: string) {
    const client = useAppSupabaseClient()
    status.value = 'loading'
    error.value = null
    try {
      const { data, error: err } = await client.auth.signInWithPassword({
        email,
        password,
      })
      if (err) throw err
      const sessionUser = data.user
      user.value = sessionUser
        ? { id: sessionUser.id, email: sessionUser.email ?? null }
        : null
      status.value = 'success'
    }
    catch (e) {
      error.value = e instanceof Error ? e.message : 'Не вдалося увійти'
      status.value = 'error'
      throw e
    }
  }

  async function logout() {
    const client = useAppSupabaseClient()
    status.value = 'loading'
    error.value = null
    try {
      const { error: err } = await client.auth.signOut()
      if (err) throw err
      user.value = null
      status.value = 'success'
    }
    catch (e) {
      error.value = e instanceof Error ? e.message : 'Не вдалося вийти'
      status.value = 'error'
    }
  }

  return {
    user,
    status,
    error,
    initialized,
    isAuthenticated,
    isLoading,
    init,
    login,
    logout,
  }
})
