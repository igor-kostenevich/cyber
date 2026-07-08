import { defineStore } from 'pinia'
import type { AsyncStateStatus } from '~/types'
import type { Reward } from '~/types/activity'

export interface RewardPatch {
  name?: string
  price_points?: number
  is_available?: boolean
  image_url?: string | null
}

export const useRewardsStore = defineStore('rewards', () => {
  const items = ref<Reward[]>([])
  const status = ref<AsyncStateStatus>('idle')
  const error = ref<string | null>(null)

  const isLoading = computed(() => status.value === 'loading')
  const hasLoaded = computed(() => status.value === 'success' || status.value === 'error')

  function getById(id: string) {
    return items.value.find((r) => r.id === id) ?? null
  }

  async function fetchAll() {
    const client = useAppSupabaseClient()
    status.value = 'loading'
    error.value = null
    try {
      const { data, error: err } = await client
        .from('rewards')
        .select('*')
        .order('sort_order', { ascending: true })

      if (err) throw err
      items.value = (data ?? []) as Reward[]
      status.value = 'success'
    }
    catch (e) {
      error.value = e instanceof Error ? e.message : 'Не вдалося завантажити нагороди'
      status.value = 'error'
    }
  }

  async function refreshOne(id: string) {
    const client = useAppSupabaseClient()
    const { data } = await client.from('rewards').select('*').eq('id', id).maybeSingle()
    if (data) {
      const idx = items.value.findIndex((r) => r.id === id)
      if (idx >= 0) items.value[idx] = data as Reward
      else items.value.push(data as Reward)
    }
  }

  async function adjustStock(id: string, delta: number) {
    const client = useAppSupabaseClient()
    const { error: err } = await client.rpc('adjust_stock', { p_reward_id: id, p_delta: delta })
    if (err) throw err
    await refreshOne(id)
  }

  async function addStock(id: string, qty: number) {
    await adjustStock(id, qty)
  }

  async function updateReward(id: string, patch: RewardPatch) {
    const client = useAppSupabaseClient()
    const { error: err } = await client.rpc('update_reward', {
      p_reward_id: id,
      p_name: patch.name ?? null,
      p_price_points: patch.price_points ?? null,
      p_is_available: patch.is_available ?? null,
      p_image_url: patch.image_url === undefined ? null : patch.image_url,
    })
    if (err) throw err
    await refreshOne(id)
  }

  async function createReward(name: string, pricePoints: number, initialStock = 0): Promise<string> {
    const client = useAppSupabaseClient()
    const { data, error: err } = await client.rpc('create_reward', {
      p_name: name,
      p_price_points: pricePoints,
      p_initial_stock: initialStock,
    })
    if (err) throw err
    await fetchAll()
    return data as string
  }

  async function deleteReward(id: string) {
    const client = useAppSupabaseClient()
    const { error: err } = await client.rpc('delete_reward', { p_reward_id: id })
    if (err) throw err
    items.value = items.value.filter((r) => r.id !== id)
  }

  return {
    items,
    status,
    error,
    isLoading,
    hasLoaded,
    getById,
    fetchAll,
    refreshOne,
    addStock,
    adjustStock,
    updateReward,
    createReward,
    deleteReward,
  }
})
