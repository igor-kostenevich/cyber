import { defineStore } from 'pinia'
import type { AppSettings, AsyncStateStatus } from '~/types'

export const useSettingsStore = defineStore('settings', () => {
  const data = ref<AppSettings | null>(null)
  const status = ref<AsyncStateStatus>('loading')
  const error = ref<string | null>(null)

  const isLoading = computed(
    () => status.value === 'loading' || data.value === null,
  )
  const hasLoaded = computed(() => status.value === 'success')

  async function fetch() {
    const client = useAppSupabaseClient()
    status.value = 'loading'
    error.value = null
    try {
      const { data: row, error: err } = await client
        .from('app_settings')
        .select('*')
        .eq('id', 1)
        .maybeSingle()

      if (err) throw err
      if (row) data.value = row as AppSettings
      status.value = 'success'
    }
    catch (e) {
      error.value = e instanceof Error ? e.message : 'Не вдалося завантажити налаштування'
      status.value = 'error'
    }
  }

  async function update(patch: Partial<Omit<AppSettings, 'id'>>) {
    const client = useAppSupabaseClient()
    status.value = 'loading'
    error.value = null
    try {
      const { data: row, error: err } = await client
        .from('app_settings')
        .update(patch)
        .eq('id', 1)
        .select()
        .single()

      if (err) throw err
      if (row) data.value = row as AppSettings
      status.value = 'success'
    }
    catch (e) {
      error.value = e instanceof Error ? e.message : 'Не вдалося оновити налаштування'
      status.value = 'error'
      throw e
    }
  }

  return {
    data,
    status,
    error,
    isLoading,
    hasLoaded,
    fetch,
    update,
  }
})
